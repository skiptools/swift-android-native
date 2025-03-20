import XCTest
import AndroidContext
import SwiftJNI
#if canImport(AndroidNDK)
import AndroidNDK
#endif

class AndroidContextTests : XCTestCase {
    public func testAndroidContext() throws {
        #if canImport(AndroidNDK)
        throw XCTSkip("this test is only for demo purposes")
        let nativeActivity: ANativeActivity! = nil
        AndroidContext.contextPointer = nativeActivity.clazz
        let context = try AndroidContext.application
        #endif

    }
}
