import XCTest
import AndroidContext
import SwiftJNI
#if os(Android)
import AndroidNDK
#endif

@available(iOS 14.0, *)
class AndroidContextTests : XCTestCase {
    public func testAndroidContext() throws {
        #if os(Android)
        throw XCTSkip("this test is only for demo purposes")
        let nativeActivity: ANativeActivity! = nil
        AndroidContext.contextPointer = nativeActivity.clazz
        let context = try AndroidContext.application
        #else
        throw XCTSkip("this test only exists for Android targets")
        #endif

    }
}
