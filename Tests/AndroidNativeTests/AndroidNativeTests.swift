import XCTest
import AndroidNative
#if canImport(FoundationNetworking)
import FoundationEssentials
import FoundationNetworking
#else
import Foundation
#endif

class AndroidNativeTests : XCTestCase {
    public func testNetwork() async throws {
        struct HTTPGetResponse : Decodable {
            var args: [String: String]
            var headers: [String: String]
            var origin: String?
            var url: String?
        }
        try AndroidBootstrap.setupCACerts() // needed in order to use https
        let url = URL(string: "https://httpbin.org/get?x=1")!
        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        if statusCode != 200 {
            // do not fail the test just because httpbin.org is unavailable
            throw XCTSkip("tolerating bad status code: \(statusCode ?? 0) for url: \(url.absoluteString)")
        }
        XCTAssertEqual(200, statusCode)
        let get = try JSONDecoder().decode(HTTPGetResponse.self, from: data)
        XCTAssertEqual(get.url, url.absoluteString)
        XCTAssertEqual(get.args["x"], "1")
    }

    public func testEmbedInCodeResource() async throws {
        XCTAssertEqual("Hello Android!\n", String(data: Data(PackageResources.sample_resource_txt), encoding: .utf8) ?? "")
    }

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
