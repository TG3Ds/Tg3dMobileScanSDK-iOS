# Tg3dMobileScanSDK-iOS

## Introduction

Tg3dMobileScanSDK-iOS offers an easier way to connect with TG3D body scanning features for developing an iOS app. For mobile scanning, we also used In3D iOS SDK. All APIs write in swift, but all APIs and data structures are compatable with objective-c.

For more details, you may check TG3D Scan APIs (https://mtm.tg3ds.com).

## Contents

1. [Init SDK](#init-sdk)
2. [Scan flows](#scan-flows)
3. [Scan Records and 3D models](#scan-records-and-3d-models)
4. [Body Measurements](#body-measurements)
5. [APIs](#apis)
6. [Sample Code](#sample-code)

## Init SDK

First, you must have an API-KEY. Then, retrieve and setup region to SDK.

```swift
let sdk = TG3DMobileScan(apiKey: "<YOUR API-KEY>")
sdk.currentRegion() { (rc, baseUrl) in
    if rc == 0 {
        sdk.setup(baseUrl: baseUrl)
    }
}
```

## Scan flows

0. [User sign-in](#signin)
1. Call [initMobileScan()](#initmobilescan) to init mobile scan transaction.
2. Call [prepareForRecord()](#prepareforrecord) to prepare view for camera.
3. Call [startRecordingBody()](#startrecordingbody) to start scan.
4. Call [stopRecording()](#stoprecording) to stop scan.
5. Call [uploadScans()](#uploadscans) to upload scan.

NOTE 1: You will need scanner id and session key while doing mobile scan.

NOTE 2: We limit 3 mobile scans per user per month. it is recommended to prepare multiple users while developing. Count of scan records will be reset on 1st of every month.

## Scan Records and 3D models

Use [listScanRecords()](#listscanrecords) to retrieve scan records of the user, and use [getObj()](#getobj) to retrieve OBJ 3D model URL of the scan record. Then display it with SceneKit or any other OBJ viewer.

<img src="https://github.com/TG3Ds/Tg3dSDK-iOS/raw/master/screenshots/obj_model.png" width="300">

## Body measurements

After scanning and 3D model been generated, we also analyze body measurements from the scanned model.
Use [getAutoMeasurements()](#getautomeasurements) to retrieve body measurements.

## APIs

#### Data structure - UserProfile

```swift
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
```

#### Data structure - Store

```swift
public class Store: NSObject {
    var name: String? = nil
}
```

#### Data structure - Scanner

```swift
public class Scanner: NSObject {
    var name: String? = nil
    var expired: Bool = false
    var store: Store? = nil
}
```

#### Data structure - Scanner

```swift
public class ScanRecord: NSObject {
    var tid: String? = nil
    var createdAt: String? = nil
    var updatedAt: String? = nil
}
```

#### checkAccount()

Check availability of the account

```swift
@objc
public func checkAccount(username: String,
                         completion: @escaping (Int, Bool) -> ())
```
##### Parameters

- username: The account to check availability.
- completion(rv, available): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 
  - available: 'true' if the account is available.


#### registerByEmail()

Register a new account by email address.

```swift
@objc
public func registerByEmail(email: String,
                            password: String,
                            completion: @escaping (Int, String?) -> ())
```

##### Parameters
- email: The email address.
- password: The password for this account.
- completion(rv, username): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 
  - username: The username of the created account.


#### signin()

Signin the account.

```swift
@objc
public func signin(username: String,
                   password: String,
                   completion: @escaping (Int) -> ())
```

##### Parameters
- username: The username which is returned by register APIs.
- password: The password for this account.
- completion(rv, username): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 


#### getUserProfile()

Get the user’s profile.

```swift
@objc
public func getUserProfile(completion: @escaping (Int, UserProfile?) -> ())
```

##### Parameters
- completion(rv, userProfile): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 
  - userProfile: User profile in UserProfile.


#### updateUserProfile()

Set the user’s profile

```swift
@objc
public func updateUserProfile(profile: UserProfile, completion: @escaping (Int) -> ())
```

##### Parameters
- userProfile: User profile in UserProfile.
- completion(rv): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 


#### listScanRecords()

Get the scan records, will return the scan records for this user.

```swift
@objc
public func listScanRecords(offset: Int,
                            limit: Int,
                            completion: @escaping (Int, Int, [ScanRecord]) -> ())
```

##### Parameters
- limit: The number of records to return, default value is 20, and maximum value is 100.
- offset: The offset of records to return, default value is 0, use for doing pagination.
- completion(rv, total, scanRecords): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 
  - total: Number of scan records.
  - scanRecords: Scan records in ScanRecord.


#### initMobileScan()

Initiate a mobile scan transaction.

```swift
@objc
public func initMobileScan(scannerId: String,
                           sessionKey: String,
                           userHeight: Int,
                           completion: @escaping (Int, String?) -> ())
```

##### Parameters
- scannerId: Scanner id of your mobile scan.
- sessionKey: Session key of your mobile scan.
- userHeight: User height in CM.
- completion(rv, tid): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 
  - tid: Transaction id for this scan.


#### prepareForRecord()

Prepare view for starting mobile scan.

```swift
@objc
public func prepareForRecord(preview: MTKView,
                             completion: @escaping ((Int) -> Void))
```

##### Parameters
- preview: MTKView to preview mobile scan camera.
- completion(rv): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 


#### startRecordingBody()

Start recording.

```swift
@objc
public func startRecordingBody()
```

#### cancelRecording()

Cancel recording.

```swift
@objc
public func cancelRecording()
```

#### stopRecording()

Stop recording.

```swift
@objc
public func stopRecording(completion: @escaping ((Int, URL?) -> Void))
```

##### Parameters
- completion(rv, url): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 
  - url: Url of recorded video for preview.

#### uploadScans()

Upload mobile scan, and it will process on the cloud, generate 3D model and analyze body measurements.

```swift
@objc
public func uploadScans(
    progress: @escaping (Double, Int64) -> (),
    completion: @escaping (Int, _) -> ()
)
```

##### Parameters
- progress(percentage, total): Callback function for uploading progress.
  - percentage: Uploading percentage.
  - total: Total bytes.
- completion(rv): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 


#### getObj()

Get OBJ model URL for the scan record.

```swift
@objc
public func getObj(tid: String,
                   completion: @escaping (Int, String?) -> ())
```

##### Parameters
- tid: Transaction id for the scan record.
- completion(rv, url): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 
  - url: Zipped OBJ model URL of the scan record.

#### getAutoMeasurements()

Get the auto measurements for the scan record.

```swift
@objc
public func getAutoMeasurements(tid: String,
                                completion: @escaping (Int, [String: Any]?) -> ())
```

##### Parameters
- tid: Transaction id for the scan record.
- completion(rv, measurements): Callback function on operation completed.
  - rv: Return value. Got 0 means the operation works fine. Got non-zero value is error code. 
  - measurements: Body measurements of the scan record in dict format.


## Sample Code

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

Since mobile scan we use In3D solution, you need to install in3D-iOS-SDK.

```ruby
pod 'I3DRecorder', :git => 'https://github.com/in3D-io/in3D-iOS-SDK.git'
```

or, with a specific version

```ruby
pod 'I3DRecorder', :git => 'https://github.com/in3D-io/in3D-iOS-SDK.git', :commit => 'ecacda7'
```

## Installation

Tg3dMobileScanSDK-iOS is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Tg3dMobileScanSDK-iOS'
```

## Author

TG3D Developer, tg3ddeveloper@tg3ds.com

## License

Tg3dMobileScanSDK-iOS is available under the MIT license. See the LICENSE file for more info.
