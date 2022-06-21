// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import Tg3dSDK_iOS

class Tg3dSDKSpec: QuickSpec {
    var sdk: TG3DMobileScan?

    override func spec() {
        describe("TG3D SDK") {
            beforeSuite {
                self.sdk = TG3DMobileScan(apiKey: "",
                                          baseUrl: "https://apidev.tg3ds.com")
                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.signin(username: "",
                                     password: "") { (rc) in
                        expect(rc).to(equal(0))
                        done()
                    }
                }
            }

            it("check account") {
                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.checkAccount(username: "test1@tg3ds.com") { (rc, available) in
                        expect(rc).to(equal(0))
                        expect(available).to(equal(false))
                        done()
                    }
                }
                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.checkAccount(username: "notexiseaccount@tg3ds.com") { (rc, available) in
                        expect(rc).to(equal(0))
                        expect(available).to(equal(true))
                        done()
                    }
                }
            }

            it("get user profile") {
                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.getUserProfile() { (rc, profile) in
                        expect(rc).to(equal(0))
                        expect(profile).toNot(beNil())
                        done()
                    }
                }
            }

            it("update user profile") {
                var userProfile: UserProfile?
                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.getUserProfile() { (rc, profile) in
                        expect(rc).to(equal(0))
                        expect(profile).toNot(beNil())
                        userProfile = profile
                        done()
                    }
                }
                let height = Int.random(in: 120...200)
                userProfile!.height = height
                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.updateUserProfile(profile: userProfile!) { (rc) in
                        expect(rc).to(equal(0))
                        done()
                    }
                }
                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.getUserProfile() { (rc, profile) in
                        expect(rc).to(equal(0))
                        expect(profile).toNot(beNil())
                        expect(profile!.height).to(equal(height))
                        userProfile = profile
                        done()
                    }
                }
            }

            it("get user scan records") {
                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.listScanRecords(offset:0, limit: 5) { (rc, total, records) in
                        expect(rc).to(equal(0))
                        expect(total).toNot(equal(0))
                        expect(records).toNot(beNil())
                        done()
                    }
                }
            }

            it("get user scan records and get obj url") {
                var tid: String = ""
                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.listScanRecords(offset:0, limit: 1) { (rc, total, records) in
                        expect(rc).to(equal(0))
                        expect(total).toNot(equal(0))
                        expect(records).toNot(beNil())

                        tid = records[0].tid!
                        done()
                    }
                }

                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.getObj(tid: tid) { (rc, objUrl) in
                        expect(rc).to(equal(0))
                        expect(objUrl).toNot(beNil())
                        done()
                    }
                }
            }

            it("get user scan records and get auto measurements") {
                var tid: String = ""
                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.listScanRecords(offset:0, limit: 1) { (rc, total, records) in
                        expect(rc).to(equal(0))
                        expect(total).toNot(equal(0))
                        expect(records).toNot(beNil())

                        tid = records[0].tid!
                        done()
                    }
                }

                waitUntil(timeout: .seconds(30)) { done in
                    self.sdk!.doGetAutoMeasurements(tid: tid) { (rc, result) in
                        expect(rc).to(equal(0))
                        expect(result).toNot(beNil())
                        expect(result!["version"]).toNot(beNil())
                        expect(result!["version"] as? String).to(equal("2.0"))
                        done()
                    }
                }
            }
        }
    }
}
