import XCTest
import AndroidLooper

@available(iOS 14.0, *)
class AndroidLooperTests : XCTestCase {
    override func setUp() {
        #if os(Android)
        //AndroidLooper_initialize(nil)
        #endif
    }

    public func testLooper() async throws {
    }
}
