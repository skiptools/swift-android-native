// Copyright 2025 Skip
#if os(Android)
import Android
import AndroidNDK
#endif
import SwiftJNI
import Foundation

/// https://developer.android.com/ndk/reference/group/asset
public final class AndroidAssetManager : @unchecked Sendable {
    let assetManager: OpaquePointer // AAssetManager
    typealias AssetHandle = OpaquePointer
    
    /// Create the asset manager from the given JNI environment with a jobject pointer to the Java AssetManager.
    public init(env: UnsafeMutablePointer<JNIEnv?>, peer: JavaObjectPointer) {
        #if !canImport(AndroidNDK)
        fatalError("only implemented for Android")
        #else
        self.assetManager = AAssetManager_fromJava(env, peer)
        #endif
    }

    /// List the file names for each asset in the specific directory
    public func listAssets(inDirectory directory: String) -> [String]? {
        #if !canImport(AndroidNDK)
        fatalError("only implemented for Android")
        #else
        guard let assetDir = AAssetManager_openDir(assetManager, directory) else { return nil }
        defer { AAssetDir_close(assetDir) }

        var assets: [String] = []
        while let assetName = AAssetDir_getNextFileName(assetDir) {
            assets.append(String(cString: assetName))
        }
        return assets
        #endif
    }

    /// Opens the asset at the given path with the specified mode, returning nil if the asset was not found.
    public func open(from path: String, mode: AssetMode) -> Asset? {
        #if !canImport(AndroidNDK)
        fatalError("only implemented for Android")
        #else
        guard let handle = AAssetManager_open(self.assetManager, path, mode.assetMode) else {
            return nil
        }
        return Asset(handle: handle)
        #endif
    }

    /// Attempt to read the entire contents from the asset with the given name.
    public func load(from path: String) -> Data? {
        open(from: path, mode: .buffer)?.read()
    }

    /// A handle to a given Asset for an AssetManager
    public class Asset {
        let handle: AssetHandle
        var closed = false

        init(handle: AssetHandle) {
            self.handle = handle
        }

        deinit {
            close()
        }

        /// Close the asset, freeing all associated resources
        public func close() {
            if closed { return }
            closed = true
            #if !canImport(AndroidNDK)
            fatalError("only implemented for Android")
            #else
            AAsset_close(handle)
            #endif
        }

        /// Returns the total size of the asset data
        public var length: Int64 {
            assert(!closed, "asset is closed")
            #if !canImport(AndroidNDK)
            fatalError("only implemented for Android")
            #else
            return AAsset_getLength64(handle)
            #endif
        }

        /// Report the total amount of asset data that can be read from the current position
        public var remainingLength: Int64 {
            assert(!closed, "asset is closed")
            #if !canImport(AndroidNDK)
            fatalError("only implemented for Android")
            #else
            return AAsset_getRemainingLength64(handle)
            #endif
        }

        /// Returns whether this asset's internal buffer is allocated in ordinary RAM (i.e. not mmapped).
        public var isAllocated: Bool {
            assert(!closed, "asset is closed")
            #if !canImport(AndroidNDK)
            fatalError("only implemented for Android")
            #else
            return AAsset_isAllocated(handle) != 0
            #endif
        }

        /// Attempt to read 'count' bytes of data from the current offset.
        ///
        /// Returns the number of bytes read, zero on EOF, or nil on error.
        public func read(size: Int? = nil) -> Data? {
            assert(!closed, "asset is closed")
            let len = size ?? Int(self.length)
            var data = Data(count: len)

            let bytesRead: Int32 = try data.withUnsafeMutableBytes { buffer in
                #if !canImport(AndroidNDK)
                fatalError("only implemented for Android")
                #else
                AAsset_read(handle, buffer, len)
                #endif
            }

            if bytesRead < 0 {
                return nil
            }

            if Int64(bytesRead) < length {
                // Resize if we read less than expected
                data = data.prefix(Int(bytesRead))
            }

            return data
        }

        /// Seek to the specified offset within the asset data.
        public func seek(offset: Int64, whence: AssetSeek) -> Int64 {
            assert(!closed, "asset is closed")
            #if !canImport(AndroidNDK)
            fatalError("only implemented for Android")
            #else
            return AAsset_seek64(handle, offset, whence.seekMode)
            #endif
        }

        /// Open a new file descriptor that can be used to read the asset data.
        ///
        /// Returns nil if direct fd access is not possible (for example, if the asset is compressed).
        public func openFileDescriptor(offset: inout Int64, outLength: inout Int64) -> Int32? {
            assert(!closed, "asset is closed")
            #if !canImport(AndroidNDK)
            fatalError("only implemented for Android")
            #else
            let fd = AAsset_openFileDescriptor64(handle, &offset, &outLength)
            if fd < 0 { return nil }
            return fd
            #endif
        }
    }

    /// The mode for opening an asset.
    public enum AssetMode {
        case buffer
        case streaming
        case random

        var assetMode: Int32 {
            #if !canImport(AndroidNDK)
            fatalError("only implemented for Android")
            #else
            switch self {
            case .buffer:
                return Int32(AASSET_MODE_BUFFER)
            case .streaming:
                return Int32(AASSET_MODE_STREAMING)
            case .random:
                return Int32(AASSET_MODE_RANDOM)
            }
            #endif
        }
    }

    public enum AssetSeek {
        /// If whence is `SEEK_SET`, the offset is set to offset bytes
        case set
        /// If whence is `SEEK_CUR`, the offset is set to its current location plus offset bytes
        case cur
        /// If whence is `SEEK_END`, the offset is set to the size of the file plus offset bytes
        case end
        /// If whence is `SEEK_HOLE`, the offset is set to the start of the next hole greater than or equal to the supplied offset.  The definition of a hole is provided below.
        case hole
        /// If whence is `SEEK_DATA`, the offset is set to the start of the next non-hole file region greater than or equal to the supplied offset
        case data

        var seekMode: Int32 {
            #if !canImport(AndroidNDK)
            fatalError("only implemented for Android")
            #else
            switch self {
            case .set: return Int32(SEEK_SET)
            case .cur: return Int32(SEEK_CUR)
            case .end: return Int32(SEEK_END)
            case .hole: return Int32(SEEK_HOLE)
            case .data: return Int32(SEEK_DATA)
            }
            #endif
        }
    }
}
