//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftAndroidNative open source project
//
// Copyright (c) 2024-2026 Skip.dev and SwiftAndroidNative project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftAndroidNative project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Testing
import AndroidNative
import Foundation
#if os(Android)
import Android
#endif
#if canImport(FoundationNetworking)
import FoundationEssentials
import FoundationNetworking
#endif

private struct RetryableError: Error {
    let message: String
}

struct AndroidNativeTests {
    #if os(Android)
    private static let caCertsLock = NSLock()

    @Test func testSetupCACertsBuildsCompleteBundle() throws {
        try withCACertsFixture { _, expectedMinimumBytes, aggregateURL in
            #expect(FileManager.default.fileExists(atPath: aggregateURL.path))
            try expectCompleteCACerts(at: aggregateURL, expectedMinimumBytes: expectedMinimumBytes)
        }
    }

    @Test func testSetupCACertsRebuildsEmptyBundle() throws {
        try withCACertsFixture { certsFolder, expectedMinimumBytes, aggregateURL in
            try Data().write(to: aggregateURL)
            unsetenv("URLSessionCertificateAuthorityInfoFile")
            try AndroidBootstrap.setupCACerts(force: false, fromCertficateFolders: [certsFolder.path])
            let path = try #require(getenv("URLSessionCertificateAuthorityInfoFile"))
            #expect(String(cString: path) == aggregateURL.path)
            try expectCompleteCACerts(at: aggregateURL, expectedMinimumBytes: expectedMinimumBytes)
        }
    }

    @Test func testSetupCACertsRebuildsTruncatedBundle() throws {
        try withCACertsFixture { certsFolder, expectedMinimumBytes, aggregateURL in
            let completeBundle = try Data(contentsOf: aggregateURL)
            // Retain only 1 or 100 bytes, both below the certificate-size minimum.
            for truncatedSize in [1, 100] {
                try completeBundle.prefix(truncatedSize).write(to: aggregateURL)
                unsetenv("URLSessionCertificateAuthorityInfoFile")
                try AndroidBootstrap.setupCACerts(force: false, fromCertficateFolders: [certsFolder.path])
                let path = try #require(getenv("URLSessionCertificateAuthorityInfoFile"))
                #expect(String(cString: path) == aggregateURL.path)
                try expectCompleteCACerts(at: aggregateURL, expectedMinimumBytes: expectedMinimumBytes)
            }

            let attributes = try FileManager.default.attributesOfItem(atPath: aggregateURL.path)
            let size = (try #require(attributes[.size] as? NSNumber)).intValue
            let modificationDate = try #require(attributes[.modificationDate] as? Date)
            unsetenv("URLSessionCertificateAuthorityInfoFile")
            try AndroidBootstrap.setupCACerts(force: false, fromCertficateFolders: [certsFolder.path])
            let path = try #require(getenv("URLSessionCertificateAuthorityInfoFile"))
            #expect(String(cString: path) == aggregateURL.path)
            let reusedAttributes = try FileManager.default.attributesOfItem(atPath: aggregateURL.path)
            #expect((reusedAttributes[.size] as? NSNumber)?.intValue == size)
            #expect(reusedAttributes[.modificationDate] as? Date == modificationDate)
        }
    }

    private func withCACertsFixture(_ body: (URL, Int, URL) throws -> Void) throws {
        // These tests share a process-wide environment variable.
        Self.caCertsLock.lock()
        defer { Self.caCertsLock.unlock() }
        let previousPath = getenv("URLSessionCertificateAuthorityInfoFile").map { String(cString: $0) }
        defer {
            if let previousPath {
                setenv("URLSessionCertificateAuthorityInfoFile", previousPath, 1)
            } else {
                unsetenv("URLSessionCertificateAuthorityInfoFile")
            }
        }

        let certsFolder = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: certsFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: certsFolder) }
        var expectedMinimumBytes = 0
        for name in ["aaaaaaaa.0", "bbbbbbbb.0", "cccccccc.0", "dddddddd.0"] {
            let certificate = """
            -----BEGIN CERTIFICATE-----
            YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXo=
            MDEyMzQ1Njc4OWFiY2RlZmdoaWprbG1ub3A=
            cXJzdHV2d3h5ejAxMjM0NTY3ODlhYmNkZWY=
            -----END CERTIFICATE-----
            Test certificate metadata for \(name)

            """.data(using: .utf8)!
            expectedMinimumBytes += certificate.count
            try certificate.write(to: certsFolder.appendingPathComponent(name))
        }

        unsetenv("URLSessionCertificateAuthorityInfoFile")
        try AndroidBootstrap.setupCACerts(force: false, fromCertficateFolders: [certsFolder.path])
        let path = try #require(getenv("URLSessionCertificateAuthorityInfoFile"))
        let aggregateURL = URL(fileURLWithPath: String(cString: path))
        defer { try? FileManager.default.removeItem(at: aggregateURL) }
        try body(certsFolder, expectedMinimumBytes, aggregateURL)
    }

    private func expectCompleteCACerts(at aggregateURL: URL, expectedMinimumBytes: Int) throws {
        let bundle = try Data(contentsOf: aggregateURL)
        #expect(bundle.count >= expectedMinimumBytes)
        let text = try #require(String(data: bundle, encoding: .utf8))
        #expect(text.components(separatedBy: "-----BEGIN CERTIFICATE-----").count - 1 == 4)
        let files = try FileManager.default.contentsOfDirectory(atPath: aggregateURL.deletingLastPathComponent().path)
        #expect(!files.contains { $0.hasSuffix(".tmp") })
    }
    #endif

    @Test(.disabled("temporarily disabled on Android due to hang"))
    func testNetwork() async throws {
        #if os(Android)
        try AndroidBootstrap.setupCACerts() // needed in order to use https
        #endif

        /// https://www.swift.org/openapi/openapi.html#/Toolchains/listReleases
        struct SwiftReleasesResponse: Decodable {
            var name: String
            var date: String?
            var tag: String?
        }

        // retry a few times in case of hiccups
        try await retry(count: 5) {
            let url = URL(string: "https://www.swift.org/api/v1/install/releases.json")!
            let (data, response) = try await URLSession.shared.data(from: url)
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            if statusCode != 200 {
                // throw with bad error so we retry
                throw RetryableError(message: "bad status code: \(statusCode ?? 0) for url: \(url.absoluteString)")
            }
            #expect(statusCode == 200)
            let get = try JSONDecoder().decode([SwiftReleasesResponse].self, from: data)
            #expect(get.count > 0)
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
                try await Task.sleep(nanoseconds: UInt64(2 + (retry * retry)) * 1_000_000_000)
            }
        }
    }

    @Test func testEmbedInCodeResource() async throws {
        #expect(String(data: Data(PackageResources.sample_resource_txt), encoding: .utf8) == "Hello Android!\n")
    }

    @Test(.disabled("temporarily disabled on Android due to hang"))
    func testMainActor() async {
        let actorDemo = await MainActorDemo()
        let result = await actorDemo.add(n1: 1, n2: 2)
        #expect(result == 3)
        var tasks: [Task<Int, Never>] = []

        for i in 0..<100 {
            tasks.append(
                Task(priority: [.low, .medium, .high].randomElement()!) {
                    assert(!Thread.isMainThread)
                    return await actorDemo.add(n1: i, n2: i)
                })
        }

        var totalResult = 0
        for task in tasks {
            let taskResult = await task.value
            totalResult += taskResult
        }

        #expect(totalResult == 9900)
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
