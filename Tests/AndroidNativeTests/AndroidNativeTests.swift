import XCTest
import AndroidNative

class AndroidNativeTests : XCTestCase {
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func testMainActor() async {
        let actorDemo = await MainActorDemo()
        let result = await actorDemo.add(n1: 1, n2: 2)
        XCTAssertEqual(result, 3)
        var tasks: [Task<Int, Never>] = []

        for i in 0..<100 {
            tasks.append(Task(priority: [.low, .medium, .high].randomElement()!) {
                assert(!Thread.isMainThread)
                return await actorDemo.add(n1: i, n2: i)
            })
        }

        var totalResult = 0
        for task in tasks {
            let taskResult = await task.value
            totalResult += taskResult
        }

        XCTAssertEqual(9900, totalResult)
    }
}

@MainActor class MainActorDemo {
    init() {
    }

    func add(n1: Int, n2: Int) -> Int {
        assert(Thread.isMainThread)
        return n1 + n2
    }
}
