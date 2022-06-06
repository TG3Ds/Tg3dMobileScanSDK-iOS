//
//  ViewController.swift
//  Tg3dSDK-iOS
//
//  Created by Wukon Hsieh on 04/22/2022.
//  Copyright (c) 2022 Wukon Hsieh. All rights reserved.
//

import UIKit
import MetalKit
import Tg3dSDK_iOS
import SceneKit
import ZIPFoundation

class ViewController: UIViewController {

    @IBOutlet weak var accountInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    @IBOutlet weak var signinButton: UIButton!

    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var lastScanLabel: UILabel!
    @IBOutlet weak var tidLabel: UILabel!
    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var nextButton: UIButton!

    @IBOutlet weak var previewView: MTKView!
    @IBOutlet weak var startScanButton: UIButton!

    let apiKey: String = "" // your apikey
    let scannerId: String = "" // your scanner ID
    let sessionKey: String = "" // your session key

    var sdk: TG3DMobileScan?
    var userProfile: UserProfile?
    var lastScanRecord: ScanRecord?
    var currentSegue: String = ""
    var isScanning: Bool = false
    var tid: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.sdk == nil {
            self.sdk = TG3DMobileScan(apiKey: self.apiKey)
            self.sdk!.currentRegion(useDev: false) { (rc, baseUrl) in
                if rc == 0 {
                    self.sdk!.setup(baseUrl: baseUrl)
                }
            }
        }
        if self.currentSegue == "showMainPage" {
            if self.userProfile != nil {
                self.userNameLabel.text = "User Name: " + self.userProfile!.name!
            }
            if self.lastScanRecord != nil {
                self.tidLabel.text = "TID: " + self.lastScanRecord!.tid!
                self.lastScanLabel.text = "Last Scan: " + self.lastScanRecord!.updatedAt!
                self.sdk!.getObj(tid: self.lastScanRecord!.tid!) { (rc, url) in
                    print(String(format: "getObj(), rc = %d", rc))
                    print(String(format: "Obj URL: %@", url!))

                    // TODO: download zipped obj and show with viewer
                    // get path of directory
                    guard let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                        return
                    }

                    let fileManager = FileManager()

                    // create file url
                    let fileUrl = directory.appendingPathComponent("model.zip")
                    try? fileManager.removeItem(at: fileUrl)

                    // starts download
                    let session = URLSession(configuration: .default)
                    var request = try! URLRequest(url: URL(string: url!)!)
                    request.httpMethod = "GET"
                    let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                        if let tempLocalUrl = tempLocalUrl, error == nil {
                            // Success
                            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                                print("Success: \(statusCode)")
                            }

                            do {
                                try FileManager.default.copyItem(at: tempLocalUrl, to: fileUrl)
                                print("downloaded..")

                                var destinationURL = fileManager.temporaryDirectory
                                destinationURL.appendPathComponent("models")
                                try? fileManager.removeItem(at: destinationURL)

                                try fileManager.unzipItem(at: fileUrl, to: destinationURL)
                                let files = try FileManager.default.contentsOfDirectory(at: destinationURL,
                                                                                        includingPropertiesForKeys: nil,
                                                                                        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants])
                                print(files)
                                if files.count > 0 {
                                    print(files[0])
                                    guard let scene = try? SCNScene(url: files[0]) else {
                                        print("failed to load obj.")
                                        return
                                    }
                                    let cameraNode = SCNNode()
                                    cameraNode.camera = SCNCamera()
                                    cameraNode.camera!.zNear = 1
                                    cameraNode.camera!.zFar = 2000
                                    cameraNode.position = SCNVector3(x: 0, y: 1500, z: 1000) // unit is mm
                                    scene.rootNode.addChildNode(cameraNode)
                                    self.sceneView.autoenablesDefaultLighting = true
                                    self.sceneView.showsStatistics = true
                                    self.sceneView.allowsCameraControl = true
                                    self.sceneView.backgroundColor = UIColor.gray
                                    self.sceneView.cameraControlConfiguration.allowsTranslation = false
                                    self.sceneView.scene = scene
                                    print("3D ok.")
                                }
                                try? fileManager.removeItem(at: fileUrl)

                            } catch (let writeError) {
                                print(writeError)
                                print("error writing file")
                            }

                        } else {
                            print("Failure: %@", error?.localizedDescription);
                        }
                    }
                    task.resume()
                }
            }
        }
        if self.currentSegue == "showScanPage" {
            var userHeight = self.userProfile!.height
            if userHeight <= 0 {
                userHeight = 180
            }
            self.sdk!.initMobileScan(scannerId: self.scannerId,
                                     sessionKey: self.sessionKey,
                                     userHeight: userHeight) { (rc, tid) in
                self.tid = tid!
                // TODO: handle if rc = 40306: 'Number of scans over limit'
                print(String(format: "initMobileScan(), rc = %d, tid: %@", rc, tid!))
                self.previewView.depthStencilPixelFormat = .invalid
                self.sdk!.prepareForRecord(preview: self.previewView) { (rc) in
                    print(String(format: "prepareForRecord(), rc = %d", rc))
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // pass data between storyboards
        if let destinationViewController = segue.destination as? ViewController {
            destinationViewController.sdk = self.sdk
            destinationViewController.userProfile = self.userProfile
            destinationViewController.lastScanRecord = self.lastScanRecord
            destinationViewController.currentSegue = segue.identifier!
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidDisappear(_ animated : Bool) {

    }

    @IBAction func onClick(_ sender: Any) {
        let email: String = accountInput.text ?? ""
        let password: String = passwordInput.text ?? ""
        self.signinButton.isEnabled = false
        DispatchQueue.main.async {
            self.sdk!.signin(accountId: email,
                             password: password) { (rc) in
                print(String(format: "signin(), rc = %d", rc))
                if rc == 0 {
                    self.sdk!.getUserProfile() { (rc, userProfile) in
                        print(String(format: "getUserProfile(), rc = %d", rc))
                        self.userProfile = userProfile
                        self.sdk!.listScanRecords(offset: 0, limit: 3) { (rc, total, records) in
                            print(String(format: "listScanRecords(), rc = %d", rc))
                            if records.count > 0 {
                                self.lastScanRecord = records[0]
                            }
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "showMainPage", sender: self)
                                self.signinButton.isEnabled = true
                            }
                        }
                    }

                } else {
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "Failed to login",
                                                                message: String(format: "Error code: %d", rc),
                                                                preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                        self.signinButton.isEnabled = true
                    }
                }

            }
        }
    }

    @IBAction func nextBtnOnClick(_ sender: Any) {
        self.performSegue(withIdentifier: "showScanPage", sender: self)
    }

    @IBAction func scanButtonOnClick(_ sender: Any) {
        if self.isScanning == false {
            var countdown = 3;
            var scanCountdown = 10;
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                if countdown > 0 {
                    self.startScanButton.setTitle(String(format: "%d", countdown), for: .normal)
                    countdown -= 1
                } else {
                    if scanCountdown == 10 {
                        self.sdk!.startRecordingBody()
                        DispatchQueue.main.async {
                            self.isScanning = true
                        }
                    }
                    if scanCountdown > 0 {
                        self.startScanButton.setTitle(String(format:"Stop(%d)", scanCountdown), for: .normal)
                        scanCountdown -= 1
                    } else {
                        timer.invalidate() // stop timer
                        DispatchQueue.main.async {
                            self.isScanning = false
                            self.startScanButton.setTitle("Uploading", for: .normal)
                            self.startScanButton.isEnabled = false

                            self.sdk!.stopRecording() { (rc, _) in
                                print("stopRecording, rc = %d", rc)
                                self.sdk!.uploadScans(progress: { (progress, totalSize) in
                                    print(String(format: "progress: %f (total: %d)", progress, totalSize))
                                }, completion: { (rc, _) in
                                    print("uploadScans, rc = %d", rc)
                                    // TODO: polling and waiting for scanning request
                                    self.sdk!.waitingForScanningResult(scannerId: self.scannerId, tid: self.tid) { (rc) in
                                        print(String(format: "waitingForScanningResult, rc = %d", rc))
                                        DispatchQueue.main.async {
                                            self.startScanButton.setTitle("Start", for: .normal)
                                            self.startScanButton.isEnabled = true
                                            self.performSegue(withIdentifier: "backMainPage", sender: self)
                                        }
                                    }
                                })
                            }
                        }
                    }
                }

            }

        } else {
            DispatchQueue.main.async {
                self.isScanning = false
                self.startScanButton.setTitle("Uploading", for: .normal)
                self.startScanButton.isEnabled = false

                self.sdk!.stopRecording() { (_, _) in
                    self.sdk!.uploadScans(progress: { (progress, totalSize) in
                        print(String(format: "progress: %f (total: %d)", progress, totalSize))
                    }, completion: { (_, err) in
                        // TODO: polling and waiting for scanning request
                        DispatchQueue.main.async {
                            self.startScanButton.setTitle("Start", for: .normal)
                            self.startScanButton.isEnabled = true
                            self.performSegue(withIdentifier: "backMainPage", sender: self)
                        }
                    })
                }
            }
        }
    }
}
