# Tg3dSDK-iOS

## Introduction

Tg3dSDK-iOS can be used to connect with TG3D body scanning features, offers an easier way to develop a TG3D body scanner app. For mobile scanning, we also used In3D iOS SDK. All APIs write in swift, but it is also compatable with objective-c.

For more details, you may check TG3D Scan APIs and APIConnect APIs.

## Contents

1. [Init SDK](#init-sdk)
2. [Scan flows](#scan-flows)
3. [3D models](#3d-models)
4. [APIs](#apis)
5. [Sample Code](#sample-code)

## Init SDK

First, you must have an API-KEY. Then, retrieve and setup region to SDK.

```swift
let sdk = TG3DMobileScan(apiKey: "<YOUR API-KEY>")
sdk.currentRegion(useDev: false) { (rc, baseUrl) in
    if rc == 0 {
        sdk.setup(baseUrl: baseUrl)
    }
}
```

## Scan flows

0. User sign-in
1. initMobileScan()
2. prepareForRecord()
3. startRecordingBody()
4. stopRecording()
5. uploadScans()

## 3D models

Use listScanRecords() and getObj() to retrieve obj URL. Then display it with SceneKit.

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

Tg3dSDK-iOS is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Tg3dSDK-iOS'
```

## Author

TG3D Developer, tg3ddeveloper@tg3ds.com

## License

Tg3dSDK-iOS is available under the MIT license. See the LICENSE file for more info.
