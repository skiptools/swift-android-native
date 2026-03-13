import Testing
import AndroidLooper

struct AndroidLooperTests {
    init() {
        #if os(Android)
        //AndroidLooper_initialize(nil)
        #endif
    }

    @Test func testLooper() async throws {
    }
}
