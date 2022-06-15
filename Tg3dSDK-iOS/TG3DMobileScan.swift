import Foundation
import I3DRecorder
import MetalKit

@objc
public enum TG3DIn3DInitError: Int {
    case none                    = 0
    case scanNotInited           = -1001
    case cameraSetupError        = -1002
    case cameraAccessDenied      = -1003
    case cameraAccessRestricted  = -1004
}

/// Wrapper for RecordState
@objc
public enum TG3DMobileScanState: Int {
    case ready
    case scanning
    case finished
}

@objc
public class User: NSObject {
    var nickName: String? = nil
    var avatarUrl: String? = nil
    var avatarThumbUrl: String? = nil
    var height: Int = 0
}

@objc
public class UserProfile: NSObject {
    var name: String? = nil
    var gender: Int = 0
    var birthday: String? = nil
    var height: Int = 0
    var weight: Int = 0
    var telephone: String? = nil
    var mobilePhone: String? = nil
    var email: String? = nil
    var address: String? = nil
    var avatarUrl: String? = nil
    var avatarThumbUrl: String? = nil
}

@objc
public class Store: NSObject {
    var name: String? = nil
}

@objc
public class Scanner: NSObject {
    var name: String? = nil
    var expired: Bool = false
    var store: Store? = nil
}

@objc
public class ScanRecord: NSObject {
    var tid: String? = nil
    var createdAt: String? = nil
    var updatedAt: String? = nil
}


func doHttpHead(url:String,
                header: Dictionary<String, String>,
                completion: @escaping (Data?, URLResponse?, Error?) -> ()) throws {
    let request: URLRequest
    request = try URLRequest.createRequest(
        method: .head,
        url: URL(string: url)!,
        parameters: nil,
        header: header,
        body: nil,
        encoding: .json
    )
    let session = URLSession.shared
    let task = session.dataTask(with: request) { (data, response, error) in
        completion(data, response, error)
    }
    task.resume()
}

func doHttpGet(url:String,
               header: Dictionary<String, String>,
               completion: @escaping (Data?, URLResponse?, Error?) -> ()) throws {
    let request: URLRequest
    request = try URLRequest.createRequest(
        method: .get,
        url: URL(string: url)!,
        parameters: nil,
        header: header,
        body: nil,
        encoding: .json
    )
    let session = URLSession.shared
    let task = session.dataTask(with: request) { (data, response, error) in
        completion(data, response, error)
    }
    task.resume()
}

func doHttpPost(url:String,
                header: Dictionary<String, String>,
                body: Dictionary<String, Any>,
                completion: @escaping (Data?, URLResponse?, Error?) -> ()) throws {
    let request: URLRequest
    request = try URLRequest.createRequest(
        method: .post,
        url: URL(string: url)!,
        parameters: nil,
        header: header,
        body: body,
        encoding: .json
    )
    let session = URLSession.shared
    let task = session.dataTask(with: request) { (data, response, error) in
        completion(data, response, error)
    }
    task.resume()
}

func retrieveRegion(useDev: Bool = false, completion: @escaping (Int, String?) -> ()) {
    let url = "https://apiselector.tg3ds.com"
    do {
        let header = [ String: String ]()
        try doHttpHead(url: url, header: header) { (data, response, error) in
            if error != nil {
                completion(-1, nil)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                completion(-1, nil)
                return
            }

            var baseUrl = ""
            if let location = response.allHeaderFields["Location"] as? String {
                baseUrl = location
            } else {
                var components = URLComponents()
                components.scheme = response.url!.scheme
                components.host = response.url!.host
                baseUrl = components.url!.absoluteString
            }
            completion(0, baseUrl)
        }

    } catch {
        return
    }
}

@objc
public class TG3DMobileScan: NSObject {
    @objc public var apiKey: String
    @objc public var baseUrl: String
    @objc public var accountId: String
    @objc public var authToken: String
    @objc public var accessToken: String
    @objc public var lastErrorCode: Int
    @objc public var lastErrorMsg: String
    @objc public weak var delegate: TG3DMobileScanDelegate?
    @objc public var tid: String?
    @objc public var in3dId: String?

    var scanService: ScanService = I3DScanService.shared
    var recorder: Recorder?
    var recording: ScanRecording?
    var settings: RecorderSettings?

    @objc
    public init(apiKey: String, baseUrl: String = "https://api.tg3ds.com") {
        self.apiKey = apiKey
        self.baseUrl = baseUrl
        self.accountId = ""
        self.authToken = ""
        self.accessToken = ""
        self.lastErrorCode = -1
        self.lastErrorMsg = ""
        self.tid = ""
        self.in3dId = ""
        self.recorder = nil
        self.recording = nil
        self.settings = nil
        super.init()
    }

    @objc
    func setup(baseUrl: String = "https://api.tg3ds.com") {
        self.baseUrl = baseUrl
    }

    @objc
    func currentRegion(useDev: Bool = false, completion: @escaping (Int, String) -> ()) {
        retrieveRegion(useDev: useDev) { (rc, url) in
            var baseUrl = "https://api.tg3ds.com"
            if rc == 0 {
                baseUrl = url!
            }
            if useDev {
                baseUrl = baseUrl.replacingOccurrences(of:"api.", with: "apidev.")
            }
            completion(0, baseUrl)
        }
    }

    func doAPIHttpGet(url:String,
                      header: Dictionary<String, String>,
                      completion: @escaping (Int, Data?, HTTPURLResponse?) -> ()) throws {
        try doHttpGet(url: url, header: header) { (data, response, error) in
            if error != nil {
                self.lastErrorCode = -1
                self.lastErrorMsg = "Unknown error (got error from http request)"
                completion(-1, nil, nil)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                self.lastErrorCode = -1
                self.lastErrorMsg = "Unknown error (no http response)"
                completion(-1, nil, nil)
                return
            }
            guard let data = data else {
                self.lastErrorCode = -1
                self.lastErrorMsg = "no data"
                completion(-1, nil, nil)
                return
            }

            do {
                if response.statusCode / 200 == 1 {
                    completion(0, data, response)

                } else if response.statusCode >= 400 && response.statusCode < 500 {
                    if !data.isEmpty {
                        let result = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        self.lastErrorCode = result.error.errno
                        self.lastErrorMsg = result.error.msg
                    } else {
                        self.lastErrorCode = response.statusCode
                        self.lastErrorMsg = ""
                    }
                    completion(self.lastErrorCode, data, response)

                } else {
                    self.lastErrorCode = response.statusCode
                    self.lastErrorMsg = "internal server error"
                    completion(self.lastErrorCode, data, response)
                }

            } catch {
                self.lastErrorCode = -1
                self.lastErrorMsg = error.localizedDescription
                completion(self.lastErrorCode, data, response)
            }
        }
    }

    func doAPIHttpPost(url:String,
                       header: Dictionary<String, String>,
                       body: Dictionary<String, Any>,
                       completion: @escaping (Int, Data?, HTTPURLResponse?) -> ()) throws {
        try doHttpPost(url: url, header: header, body: body) { (data, response, error) in
            if error != nil {
                self.lastErrorCode = -1
                self.lastErrorMsg = "Unknown error (got error from http request)"
                completion(-1, nil, nil)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                self.lastErrorCode = -1
                self.lastErrorMsg = "Unknown error (no http response)"
                completion(-1, nil, nil)
                return
            }
            do {
                if response.statusCode / 200 == 1 {
                    completion(0, data, response)

                } else if response.statusCode >= 400 && response.statusCode < 500 {
                    guard let data = data else {
                        self.lastErrorCode = -1
                        self.lastErrorMsg = "no data"
                        completion(-1, nil, nil)
                        return
                    }
                    if !data.isEmpty {
                        let result = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        self.lastErrorCode = result.error.errno
                        self.lastErrorMsg = result.error.msg
                    } else {
                        self.lastErrorCode = response.statusCode
                        self.lastErrorMsg = ""
                    }
                    completion(self.lastErrorCode, data, response)

                } else {
                    self.lastErrorCode = response.statusCode
                    self.lastErrorMsg = "internal server error"
                    completion(self.lastErrorCode, data, response)
                }

            } catch {
                self.lastErrorCode = -1
                self.lastErrorMsg = error.localizedDescription
                completion(self.lastErrorCode, data, response)
            }
        }
    }

    @objc
    func doRegisterByEmail(email: String,
                           password: String,
                           completion: @escaping (Int, String?) -> ()) {
        let url = String(format:"%@/api/v1/users/register_email?apikey=%@", arguments:[self.baseUrl, self.apiKey])
        do {
            let header = [ String: String ]()
            let body = [ "email": email, "password": password, "provider": 0 ] as [String : Any]
            try self.doAPIHttpPost(url: url, header: header, body: body) { (rc, data, response) in
                if rc != 0 {
                    completion(rc, nil)
                    return
                }
                guard let data = data else {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = "no data"
                    completion(self.lastErrorCode, nil)
                    return
                }
                do {
                  guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                      // appropriate error handling
                      self.lastErrorCode = -1
                      self.lastErrorMsg = "invalid data format(response is not json)"
                      completion(self.lastErrorCode, nil)
                      return
                  }
                  guard let username = json["username"] as? String else {
                      // appropriate error handling
                      self.lastErrorCode = -1
                      self.lastErrorMsg = "invalid data format(no username in response)"
                      completion(self.lastErrorCode, nil)
                      return
                  }
                  completion(0, username)

                } catch {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = error.localizedDescription
                    completion(self.lastErrorCode, nil)
                }
            }

        } catch {
            self.lastErrorCode = -1
            self.lastErrorMsg = error.localizedDescription
            completion(self.lastErrorCode, nil)
            return
        }
    }

    @objc
    func doSignin(accountId: String,
                  password: String,
                  completion: @escaping (Int, String?) -> ()) {
        let url = String(format:"%@/api/v1/users/signin?apikey=%@", arguments:[self.baseUrl, self.apiKey])
        do {
            let header = [ String: String ]()
            let body = [ "username": accountId, "password": password ]
            try self.doAPIHttpPost(url: url, header: header, body: body) { (rc, data, response) in
                if rc != 0 {
                    completion(rc, nil)
                    return
                }
                guard let data = data else {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = "no data"
                    completion(self.lastErrorCode, nil)
                    return
                }
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        // appropriate error handling
                        self.lastErrorCode = -1
                        self.lastErrorMsg = "invalid data format(response is not json)"
                        completion(self.lastErrorCode, nil)
                        return
                    }
                    guard let auth_token = json["auth_token"] as? String else {
                        // appropriate error handling
                        self.lastErrorCode = -1
                        self.lastErrorMsg = "invalid data format(no auth_token in response)"
                        completion(self.lastErrorCode, nil)
                        return
                    }
                    completion(0, auth_token)

                } catch {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = error.localizedDescription
                    completion(self.lastErrorCode, nil)
                }
            }

        } catch {
            self.lastErrorCode = -1
            self.lastErrorMsg = error.localizedDescription
            completion(self.lastErrorCode, nil)
            return
        }
    }

    @objc
    func doAuth(accountId: String,
                authToken: String,
                completion: @escaping (Int, String?) -> ()) {
        let url = String(format:"%@/api/v1/users/auth?apikey=%@", arguments:[self.baseUrl, self.apiKey])
        do {
            let header = [ String: String ]()
            let body = [ "username": accountId, "auth_token": authToken, "provider": 0 ] as [String : Any]
            try self.doAPIHttpPost(url: url, header: header, body: body) { (rc, data, response) in
                if rc != 0 {
                    completion(rc, nil)
                    return
                }
                guard let data = data else {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = "no data"
                    completion(self.lastErrorCode, nil)
                    return
                }
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        // appropriate error handling
                        self.lastErrorCode = -1
                        self.lastErrorMsg = "invalid data format(response is not json)"
                        completion(self.lastErrorCode, nil)
                        return
                    }
                    guard let access_token = json["access_token"] as? String else {
                        // appropriate error handling
                        self.lastErrorCode = -1
                        self.lastErrorMsg = "invalid data format(no access_token in response)"
                        completion(self.lastErrorCode, nil)
                        return
                    }
                    completion(0, access_token)

                } catch {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = error.localizedDescription
                    completion(self.lastErrorCode, nil)
                }
            }

        } catch {
            self.lastErrorCode = -1
            self.lastErrorMsg = error.localizedDescription
            completion(self.lastErrorCode, nil)
            return
        }
    }

    func doGetUserProfile(completion: @escaping (Int, [String: Any]?) -> ()) {
        let url = String(format:"%@/api/v1/users/profile?apikey=%@", arguments:[self.baseUrl, self.apiKey])
        do {
            // let header = [ String: String ]()
            let header = [ "X-User-Access-Token": self.accessToken ]
            try self.doAPIHttpGet(url: url, header: header) { (rc, data, response) in
                if rc != 0 {
                    completion(rc, nil)
                    return
                }
                guard let data = data else {
                    return
                }
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        // appropriate error handling
                        self.lastErrorCode = -1
                        self.lastErrorMsg = "invalid data format(response is not json)"
                        completion(self.lastErrorCode, nil)
                        return
                    }
                    completion(0, json)

                } catch {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = error.localizedDescription
                    completion(self.lastErrorCode, nil)
                }
            }

        } catch {
            self.lastErrorCode = -1
            self.lastErrorMsg = error.localizedDescription
            completion(self.lastErrorCode, nil)
            return
        }
    }

    @objc
    func doListScanRecords(offset: Int,
                           limit: Int,
                           completion: @escaping (Int, Int, Array<Any>) -> ()) {
        let url = String(format:"%@/api/v1/scan_records?unfold=false&apikey=%@", arguments:[self.baseUrl, self.apiKey])
        do {
            let header = [ "X-User-Access-Token": self.accessToken ]
            try self.doAPIHttpGet(url: url, header: header) { (rc, data, response) in
                if rc != 0 {
                    completion(rc, 0, [])
                    return
                }
                guard let data = data else {
                    return
                }
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        // appropriate error handling
                        self.lastErrorCode = -1
                        self.lastErrorMsg = "invalid data format(response is not json)"
                        completion(self.lastErrorCode, 0, [])
                        return
                    }
                    guard let total = json["total"] as? Int else {
                        // appropriate error handling
                        self.lastErrorCode = -1
                        self.lastErrorMsg = "invalid data format(no total in response)"
                        completion(self.lastErrorCode, 0, [])
                        return
                    }
                    let records = json["records"] as! Array<Any>
                    completion(0, total, records)

                } catch {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = error.localizedDescription
                    completion(self.lastErrorCode, 0, [])
                }
            }

        } catch {
            self.lastErrorCode = -1
            self.lastErrorMsg = error.localizedDescription
            completion(self.lastErrorCode, 0, [])
            return
        }
    }

    @objc
    func doInitScanner(scannerId: String,
                       sessionKey: String,
                       completion: @escaping (Int, [String: Any]?) -> ()) {
        let url = String(format:"%@/api/v1/scanners/%@?apikey=%@", arguments:[self.baseUrl, scannerId, self.apiKey])
        do {
            let header = [ "X-User-Access-Token": self.accessToken ]
            let body = [ "session_key": sessionKey ]
            try self.doAPIHttpPost(url: url, header: header, body: body) { (rc, data, response) in
                if rc != 0 {
                    completion(rc, nil)
                    return
                }
                guard let data = data else {
                    return
                }
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        // appropriate error handling
                        self.lastErrorCode = -1
                        self.lastErrorMsg = "invalid data format(response is not json)"
                        completion(self.lastErrorCode, nil)
                        return
                    }
                    completion(0, json)

                } catch {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = error.localizedDescription
                    completion(self.lastErrorCode, nil)
                }
            }

        } catch {
            self.lastErrorCode = -1
            self.lastErrorMsg = error.localizedDescription
            completion(self.lastErrorCode, nil)
            return
        }
    }

    func doGetObj(tid: String, completion: @escaping (Int, String?) -> ()) {
        let url = String(format:"%@/api/v1/scan_records/%@/obj?apikey=%@", arguments:[self.baseUrl, tid, self.apiKey])
        do {
            let header = [ "X-User-Access-Token": self.accessToken ]
            try doHttpHead(url: url, header: header) { (data, response, error) in
                if error != nil {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = "Unknown error (got error from http request)"
                    completion(-1, nil)
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = "Unknown error (no http response)"
                    completion(-1, nil)
                    return
                }

                if let location = response.allHeaderFields["Location"] as? String {
                    completion(0, location)
                } else {
                    completion(0, response.url!.absoluteString)
                }
            }

        } catch {
            self.lastErrorCode = -1
            self.lastErrorMsg = error.localizedDescription
            completion(self.lastErrorCode, nil)
            return
        }
    }

    func doGetAutoMeasurements(tid: String, completion: @escaping (Int, [String: Any]?) -> ()) {
        let url = String(format:"%@/api/v1/scan_records/%@/size_xt?version=4&apikey=%@", arguments:[self.baseUrl, tid, self.apiKey])
        do {
            let header = [ "X-User-Access-Token": self.accessToken ]
            try self.doAPIHttpGet(url: url, header: header) { (rc, data, response) in
                if rc != 0 {
                    completion(rc, nil)
                    return
                }
                guard let data = data else {
                    return
                }
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        // appropriate error handling
                        self.lastErrorCode = -1
                        self.lastErrorMsg = "invalid data format(response is not json)"
                        completion(self.lastErrorCode, nil)
                        return
                    }
                    completion(0, json)

                } catch {
                    self.lastErrorCode = -1
                    self.lastErrorMsg = error.localizedDescription
                    completion(self.lastErrorCode, nil)
                }
            }

        } catch {
            self.lastErrorCode = -1
            self.lastErrorMsg = error.localizedDescription
            completion(self.lastErrorCode, nil)
            return
        }
    }

    public func doWaitingForScanningResult(scannerId: String, tid: String, completion: @escaping (Int) -> ()) {
        let url = String(format:"%@/api/v1/scanners/%@/%@/wait_finish?version=4&apikey=%@", arguments:[self.baseUrl, scannerId, tid, self.apiKey])
        do {
            let header = [ "Content-Type": "application/json", "X-User-Access-Token": self.accessToken ]
            let body = [ String: String ]()
            try self.doAPIHttpPost(url: url, header: header, body: body) { (rc, data, response) in
                if rc != 0 {
                    completion(rc)
                    return
                }
                completion(0)
            }

        } catch {
            self.lastErrorCode = -1
            self.lastErrorMsg = error.localizedDescription
            completion(self.lastErrorCode)
            return
        }
    }

    @objc
    func registerByEmail(email: String,
                         password: String,
                         completion: @escaping (Int, String?) -> ()) {
      self.doRegisterByEmail(email: email, password: password) { (rc, username) in
          if rc != 0 {
              completion(rc, nil)
              return
          }
          completion(rc, username)
      }
    }

    @objc
    public func signin(accountId: String,
                       password: String,
                       completion: @escaping (Int) -> ()) {
        self.doSignin(accountId: accountId, password: password) { (rc, authToken) in
            if rc != 0 {
                completion(rc)
                return
            }
            self.authToken = authToken!
            self.doAuth(accountId: accountId, authToken: authToken!) { (rc, accessToken) in
                if rc != 0 {
                    completion(rc)
                    return
                }
                self.accessToken = accessToken!
                completion(rc)
            }
        }
    }

    @objc
    public func getUserProfile(completion: @escaping (Int, UserProfile?) -> ()) {
        self.doGetUserProfile() { (rc, result) in
            if rc != 0 {
                completion(rc, nil)
                return
            }

            let userProfile = UserProfile()
            userProfile.name = result!["nick_name"] as? String
            userProfile.gender = result!["gender"] as? Int ?? 0
            userProfile.birthday = result!["birthday"] as? String
            userProfile.height = result!["height"] as? Int ?? -1
            userProfile.weight = result!["weight"] as? Int ?? -1
            userProfile.telephone = result!["telephone"] as? String
            userProfile.mobilePhone = result!["mobile_phone"] as? String
            userProfile.email = result!["email"] as? String
            userProfile.address = result!["address"] as? String
            userProfile.avatarUrl = result!["avatar_url"] as? String
            userProfile.avatarThumbUrl = result!["avatar_thumb_url"] as? String

            completion(rc, userProfile)
        }
    }

    @objc
    public func listScanRecords(offset: Int,
                                limit: Int,
                                completion: @escaping (Int, Int, [ScanRecord]) -> ()) {
        doListScanRecords(offset: offset, limit: limit) { (rc, total, records) in
            if rc != 0 {
                completion(rc, -1, [])
                return
            }

            var scanRecords = [ScanRecord]()
            for item in records {
                let obj = item as? [String: Any]

                let record = ScanRecord()
                record.tid = obj!["tid"] as? String
                record.createdAt = obj!["created_at"] as? String
                record.updatedAt = obj!["updated_at"] as? String
                scanRecords.append(record)
            }
            completion(rc, total, scanRecords)
        }
    }

    @objc
    public func initMobileScan(scannerId: String,
                               sessionKey: String,
                               userHeight: Int,
                               completion: @escaping (Int, String?) -> ()) {
        self.doInitScanner(scannerId: scannerId, sessionKey: sessionKey) { (rc, result) in
            if rc != 0 {
                completion(rc, nil)
                return
            }

            self.tid = result!["tid"] as? String
            self.in3dId = result!["in3d_id"] as? String
            self.recording = self.scanService.newRecording(withHead: false)
            self.recorder = ScanRecorder(
                sequence: self.recording!.bodySequence!,
                height: userHeight
            )
            if self.recorder!.canUse(camera: CameraType.trueDepth, for: .body) {
                self.settings = I3DRecorderSettings(cameraType: .trueDepth)
            } else {
                self.settings = I3DRecorderSettings(cameraType: .rgbFront)
            }
            completion(0, self.tid)
        }
    }

    @objc
    public func prepareForRecord(preview: MTKView, completion: @escaping ((Int) -> Void)) {
        if self.recorder != nil {
            self.recorder!.delegate = self
            self.recorder!.previewView = preview
            self.recorder!.prepareForRecord(with: self.settings!, imageFilter: nil, sensorFilter: nil) { error in
                completion(((error as? I3DRecordInitError)?.toTG3DIn3DInitError() ?? .none).rawValue)
            }
        } else {
            completion(TG3DIn3DInitError.scanNotInited.rawValue)
        }
    }

    @objc
    public func startRecordingBody() {
        if self.recorder != nil {
            self.recorder!.startRecord()
        }
    }

    @objc
    public func cancelRecording() {
        self.stopRecording(completion: { _, _ in })
    }

    @objc
    public func stopRecording(completion: @escaping ((Int, URL?) -> Void)) {
        if self.recorder != nil {
            self.recorder!.stopRecord() { (sequence, error) in
                completion(((error as? I3DRecordInitError)?.toTG3DIn3DInitError() ?? .none).rawValue, sequence?.rgb)
            }
        }
    }

    @objc
    public func uploadScans(
        progress: @escaping (Double, Int64) -> (),
        completion: @escaping (Int, String?) -> ()
    ) {
        do {
            try scanService.recorded(recording: self.recording!)
            scanService.delegate = self
            scanService.upload(
                recording: self.recording!.id,
                progress: progress,
                completion: { (scan, error) in
                    completion(((error as? I3DRecordInitError)?.toTG3DIn3DInitError() ?? .none).rawValue, scan?.callbackURL)
                }
            )
        } catch {
            completion(((error as? I3DRecordInitError)?.toTG3DIn3DInitError() ?? .none).rawValue, nil)
            print(error)
        }
    }

    @objc
    public func waitingForScanningResult(scannerId: String, tid: String, completion: @escaping (Int) -> ()) {
        self.doWaitingForScanningResult(scannerId: scannerId, tid: tid) { (rc) in
            completion(rc)
        }
    }

    @objc
    public func getObj(tid: String, completion: @escaping (Int, String?) -> ()) {
        self.doGetObj(tid: tid) { (rc, obj_url) in
            if rc != 0 {
                completion(rc, nil)
                return
            }
            completion(rc, obj_url)
        }
    }

    @objc
    public func getAutoMeasurements(tid: String, completion: @escaping (Int, [String: Any]?) -> ()) {
        self.doGetAutoMeasurements(tid: tid) { (rc, result) in
            if rc != 0 {
                completion(rc, nil)
                return
            }
            completion(rc, result)
        }
    }
}

struct ErrorStruct: Codable {
    let errno: Int
    let msg: String
}

struct ErrorResponse: Codable {
    let error: ErrorStruct
}

// MARK: - ScanServiceDelegate
extension TG3DMobileScan: I3DRecorder.ScanServiceDelegate {
    // for uploading
    public func createScan(for recording: ScanRecording, completion: @escaping (String?) -> ()) {
        if (self.in3dId == nil || self.in3dId!.isEmpty) {
            self.lastErrorCode = -1;
            self.lastErrorMsg = "no in3d id.";
            completion(nil);
        } else {
            completion(self.in3dId);
        }
    }
}

@objc
public protocol TG3DMobileScanDelegate: AnyObject {
    @objc func recorderStateDidChange(_: TG3DMobileScanState)
}

// MARK: - RecorderDelegate
extension TG3DMobileScan: RecorderDelegate {
    public func recorder(changed state: RecordState) {
        delegate?.recorderStateDidChange(convertRecordState(state))
    }

    private func convertRecordState(_ state: RecordState) -> TG3DMobileScanState {
        switch state {
            case .ready: return .ready
            case .scanning: return .scanning
            case .finished: return .finished
            @unknown default: fatalError()
        }
    }
}

public extension I3DRecordInitError {
    func toTG3DIn3DInitError() -> TG3DIn3DInitError {
        switch self {
            case .cameraSetupError: return .cameraSetupError
            case .cameraAccessDenied: return .cameraAccessDenied
            case .cameraAccessRestricted: return .cameraAccessRestricted
            @unknown default: fatalError()
        }
    }
}
