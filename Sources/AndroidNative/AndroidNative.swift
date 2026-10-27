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

@_exported import SwiftJNI
@_exported import AndroidAssetManager
@_exported import AndroidLogging
@_exported import AndroidLooper
@_exported import AndroidChoreographer
@_exported import AndroidContext

#if canImport(Android)
import Android
import Foundation

/// Utilities for setting up Android compatibility with Foundation
public class AndroidBootstrap {
    /// Collects all the certificate files from the Android certificate store and writes them to a single `cacerts.pem` file that can be used by libcurl,
    /// which is communicated through the `URLSessionCertificateAuthorityInfoFile` environment property
    /// The aggregate is written atomically.
    /// An existing aggregate is reused only when it is at least as large as the sum of the system certificate files.
    ///
    /// See https://android.googlesource.com/platform/frameworks/base/+/8b192b19f264a8829eac2cfaf0b73f6fc188d933%5E%21/#F0
    /// See https://github.com/apple/swift-nio-ssl/blob/d1088ebe0789d9eea231b40741831f37ab654b61/Sources/NIOSSL/AndroidCABundle.swift#L30
    @available(macOS 13.0, iOS 16.0, *)
    public static func setupCACerts(force: Bool = false, fromCertficateFolders certsFolders: [String] = ["/system/etc/security/cacerts", "/apex/com.android.conscrypt/cacerts"]) throws {
        //setenv("URLSessionCertificateAuthorityInfoFile", "INSECURE_SSL_NO_VERIFY", 1) // disables all certificate verification
        //setenv("URLSessionCertificateAuthorityInfoFile", "/system/etc/security/cacerts/", 1) // doesn't work for directories

        // if someone else has already set URLSessionCertificateAuthorityInfoFile then do not override unless forced
        if !force && getenv("URLSessionCertificateAuthorityInfoFile") != nil {
            return
        }

        // get a list of all the certificate URLs
        var certURLs: [URL] = []
        for certsFolder in certsFolders {
            let certsFolderURL = URL(fileURLWithPath: certsFolder)
            if (try? certsFolderURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true { continue }
            let certFolderURLs = try FileManager.default.contentsOfDirectory(at: certsFolderURL, includingPropertiesForKeys: [.isRegularFileKey, .isReadableKey, .fileSizeKey, .contentModificationDateKey])
            for certURL in certFolderURLs {
                //logger.debug("setupCACerts: certURL=\(certURL)")
                // certificate files have names like "53a1b57a.0"
                if certURL.pathExtension != "0" { continue }
                do {
                    if try certURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == false { continue }
                    if try certURL.resourceValues(forKeys: [.isReadableKey]).isReadable == false { continue }
                    certURLs.append(certURL)
                } catch {
                    //logger.warning("setupCACerts: error reading certificate file \(certURL.path): \(error)")
                    continue
                }
            }
        }
        certURLs = certURLs.sorted { $0.path < $1.path }

        // generate a checksum of all the certificate URL names and their sizes and modification times in order to define the aggregate file name
        // we do this so was can safely cache the aggregate certificate file without re-creating it every time
        var urlSummary = ""
        var expectedMinimumBytes: Int = 0
        for certURL in certURLs {
            let fileSize = try? certURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
            expectedMinimumBytes += fileSize ?? 0
            urlSummary.append(certURL.path)
            urlSummary.append("|")
            urlSummary.append(fileSize?.description ?? "")
            urlSummary.append("|")
            urlSummary.append((try? certURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate?.timeIntervalSince1970.description) ?? "")
            urlSummary.append("|")
        }
        let checksum = crc32Checksum(of: urlSummary.data(using: .utf8) ?? Data())

        var cacheFolder = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        var cacheFolderIsDir: Bool = false
        if !FileManager.default.fileExists(atPath: cacheFolder.path, isDirectory: &cacheFolderIsDir) || !cacheFolderIsDir {
            cacheFolder = URL.temporaryDirectory
        }
        let generatedCacertsURL = cacheFolder.appendingPathComponent("cacerts-aggregate-\(checksum).pem")

        if FileManager.default.fileExists(atPath: generatedCacertsURL.path) {
            // re-use only a non-empty cached aggregate file of sufficient size
            if !force {
                let size = (try? FileManager.default.attributesOfItem(atPath: generatedCacertsURL.path)[.size] as? NSNumber)?.intValue ?? 0
                if size > 0 && size >= expectedMinimumBytes {
                    setenv("URLSessionCertificateAuthorityInfoFile", generatedCacertsURL.path, 1)
                    return
                }
            }

            // clear any previous generated certificates file that may have been created by this app
            try FileManager.default.removeItem(atPath: generatedCacertsURL.path)
        }

        let tempPath = generatedCacertsURL.path + ".\(UUID().uuidString).tmp"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }
        guard FileManager.default.createFile(atPath: tempPath, contents: nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let fs = try FileHandle(forWritingTo: URL(fileURLWithPath: tempPath))
        defer { try? fs.close() }

        // write a header
        try fs.write(contentsOf:
            """
            ## Bundle of CA Root Certificates
            ## Auto-generated on \(Date())
            ## by aggregating certificates from: \(certsFolders)

            """.data(using: .utf8)!)

        // Go through each folder and load each certificate file (ending with ".0"),
        // and smash them together into a single aggreagate file tha curl can load.
        // The .0 files will contain some extra metadata, but libcurl only cares about the
        // -----BEGIN CERTIFICATE----- and -----END CERTIFICATE----- sections,
        // so we can naïvely concatenate them all and libcurl will understand the bundle.
        for certURL in certURLs {
            try fs.write(contentsOf: try Data(contentsOf: certURL))
        }

        try fs.synchronize()
        try fs.close()
        guard rename(tempPath, generatedCacertsURL.path) == 0 else {
            throw CocoaError(.fileWriteUnknown)
        }

        setenv("URLSessionCertificateAuthorityInfoFile", generatedCacertsURL.path, 1)
    }

    private static func crc32Checksum(of data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF

        for byte in data {
            crc = crc ^ UInt32(byte)
            for _ in 0..<8 {
                if crc & 1 == 1 {
                    crc = (crc >> 1) ^ 0xEDB88320
                } else {
                    crc = crc >> 1
                }
            }
        }

        return ~crc
    }
}
#endif
