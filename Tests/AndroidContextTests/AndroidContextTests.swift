import XCTest
import AndroidContext
import SwiftJNI
#if os(Android)
import AndroidNDK
#endif

@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
class AndroidContextTests : XCTestCase {
    public func testAndroidContext() throws {
        throw XCTSkip("this test is only for demo purposes")
        #if os(Android)
        let nativeActivity: ANativeActivity! = nil
        AndroidContext.contextPointer = nativeActivity.clazz
        #endif
        let context = try AndroidContext.application
        let assetManager: AndroidAssetManager = context.assetManager
        for item in assetManager.listAssets(inDirectory: "") ?? [] {
            print("asset item: \(item)")
        }
    }
}
