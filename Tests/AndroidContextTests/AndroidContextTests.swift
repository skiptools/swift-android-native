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
import AndroidContext
import SwiftJNI
#if os(Android)
import AndroidNDK
#endif

#if !os(iOS)
struct AndroidContextTests {
    // TODO: activate these tests now that we have `skip android test --apk` and can access the JNI context
    @Test(.disabled("this test is only for demo purposes"))
    func testAndroidContext() throws {
        #if os(Android)
        let nativeActivity: ANativeActivity! = nil
        AndroidContext.contextPointer = nativeActivity.clazz
        #endif
        let context = try AndroidContext.application
        let assetManager: AndroidAssetManager = context.assetManager
        for item in assetManager.listAssets(inDirectory: "") ?? [] {
            print("asset item: \(item)")
        }
    }
}
#endif
