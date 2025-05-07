// Copyright 2025 Skip
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
    ///
    /// See https://android.googlesource.com/platform/frameworks/base/+/8b192b19f264a8829eac2cfaf0b73f6fc188d933%5E%21/#F0
    /// See https://github.com/apple/swift-nio-ssl/blob/d1088ebe0789d9eea231b40741831f37ab654b61/Sources/NIOSSL/AndroidCABundle.swift#L30
    @available(macOS 13.0, iOS 16.0, *)
    public static func setupCACerts(force: Bool = false, fromCertficateFolders certsFolders: [String] = ["/system/etc/security/cacerts", "/apex/com.android.conscrypt/cacerts"]) throws {
        // if someone else has already set URLSessionCertificateAuthorityInfoFile then do not override unless forced
        if !force && getenv("URLSessionCertificateAuthorityInfoFile") != nil {
            return
        }

        var cacheFolder = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        var cacheFolderIsDir: Bool = false
        if !FileManager.default.fileExists(atPath: cacheFolder.path, isDirectory: &cacheFolderIsDir) || !cacheFolderIsDir {
            cacheFolder = URL.temporaryDirectory
        }
        //logger.debug("setupCACerts: \(cacheFolder)")
        let generatedCacertsURL = cacheFolder.appendingPathComponent("cacerts-aggregate.pem")
        //logger.debug("setupCACerts: generatedCacertsURL=\(generatedCacertsURL)")

        let contents = try FileManager.default.contentsOfDirectory(at: cacheFolder, includingPropertiesForKeys: nil)
        //logger.debug("setupCACerts: cacheFolder=\(cacheFolder) contents=\(contents)")

        // clear any previous generated certificates file that may have been created by this app
        if FileManager.default.fileExists(atPath: generatedCacertsURL.path) {
            try FileManager.default.removeItem(atPath: generatedCacertsURL.path)
        }

        let created = FileManager.default.createFile(atPath: generatedCacertsURL.path, contents: nil)
        //logger.debug("setupCACerts: created file: \(created): \(generatedCacertsURL.path)")

        let fs = try FileHandle(forWritingTo: generatedCacertsURL)
        defer { try? fs.close() }

        // write a header
        fs.write("""
        ## Bundle of CA Root Certificates
        ## Auto-generated on \(Date())
        ## by aggregating certificates from: \(certsFolders)

        """.data(using: .utf8)!)

        // Go through each folder and load each certificate file (ending with ".0"),
        // and smash them together into a single aggreagate file tha curl can load.
        // The .0 files will contain some extra metadata, but libcurl only cares about the
        // -----BEGIN CERTIFICATE----- and -----END CERTIFICATE----- sections,
        // so we can naïvely concatenate them all and libcurl will understand the bundle.
        for certsFolder in certsFolders {
            let certsFolderURL = URL(fileURLWithPath: certsFolder)
            if (try? certsFolderURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true { continue }
            let certURLs = try FileManager.default.contentsOfDirectory(at: certsFolderURL, includingPropertiesForKeys: [.isRegularFileKey, .isReadableKey])
            for certURL in certURLs {
                //logger.debug("setupCACerts: certURL=\(certURL)")
                // certificate files have names like "53a1b57a.0"
                if certURL.pathExtension != "0" { continue }
                do {
                    if try certURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == false { continue }
                    if try certURL.resourceValues(forKeys: [.isReadableKey]).isReadable == false { continue }
                    try fs.write(contentsOf: try Data(contentsOf: certURL))
                } catch {
                    //logger.warning("setupCACerts: error reading certificate file \(certURL.path): \(error)")
                    continue
                }
            }
        }


        //setenv("URLSessionCertificateAuthorityInfoFile", "INSECURE_SSL_NO_VERIFY", 1) // disables all certificate verification
        //setenv("URLSessionCertificateAuthorityInfoFile", "/system/etc/security/cacerts/", 1) // doesn't work for directories
        setenv("URLSessionCertificateAuthorityInfoFile", generatedCacertsURL.path, 1)
        //logger.debug("setupCACerts: set URLSessionCertificateAuthorityInfoFile=\(generatedCacertsURL.path)")
    }
}
#endif

