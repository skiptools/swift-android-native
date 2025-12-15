import XCTest
import AndroidNative
#if canImport(FoundationNetworking)
import FoundationEssentials
import FoundationNetworking
#else
import Foundation
#endif

@available(iOS 14.0, *)
class AndroidNativeTests : XCTestCase {
    public func testNetwork() async throws {
        /// https://www.swift.org/openapi/openapi.html#/Toolchains/listReleases
        struct SwiftReleasesResponse : Decodable {
            var name: String
            var date: String?
            var tag: String?
        }
        #if os(Android)
        try AndroidBootstrap.setupCACerts() // needed in order to use https
        #endif

        // retry a few times in case of hiccups
        try await retry(count: 5) {
            let url = URL(string: "https://www.swift.org/api/v1/install/releases.json")!
            let (data, response) = try await URLSession.shared.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            if statusCode != 200 {
                // throw with bad error so we retry
                throw XCTSkip("bad status code: \(statusCode ?? 0) for url: \(url.absoluteString)")
            }
            XCTAssertEqual(200, statusCode)
            let get = try JSONDecoder().decode([SwiftReleasesResponse].self, from: data)
            XCTAssertGreaterThan(0, get.count)
        }
    }
    
    /// Retries the given block with an exponential backoff in between attempts.
    func retry(count retryCount: Int, block: () async throws -> ()) async throws {
        for retry in 1...retryCount {
            do {
                try await block()
                return // success: do not continue retrying
            } catch {
                if retry == retryCount {
                    throw error
                }
                // exponential backoff before retrying
                try await Task.sleep(nanoseconds: UInt64(2 + (retry * retry)) * NSEC_PER_SEC)
            }
        }
    }

    public func testEmbedInCodeResource() async throws {
        XCTAssertEqual("Hello Android!\n", String(data: Data(PackageResources.sample_resource_txt), encoding: .utf8) ?? "")
    }

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
