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
#if os(Android)
import Foundation
import AndroidAssetManager
import AndroidContext
import SwiftJNI
import CJNI
#endif

struct AndroidAssetManagerTests {
    @Test func testAssetManager() async throws {
    }

    #if os(Android)
    /// `AAssetManager_fromJava` returns memory owned by the Java AssetManager, so `AndroidAssetManager` must keep it
    /// reachable: once it is collected, `AAssetManager_open` aborts with "pthread_mutex_lock called on a destroyed mutex"
    @Test func testAssetManagerKeepsJavaPeerAlive() throws {
        try JNI.attachJVM()
        try jniContext { try Self.checkAssetManagerKeepsJavaPeerAlive() }
    }

    private static func checkAssetManagerKeepsJavaPeerAlive() throws {
        let (assetManager, weakPeer) = try createAssetManagerOnlyReferencedFromNative()
        defer { JNI.jni.withEnv { $0.DeleteWeakGlobalRef($1, weakPeer) } }

        let system = try JClass(name: "java/lang/System", systemClass: true)
        let gc = try #require(system.getStaticMethodID(name: "gc", sig: "()V"))
        let runFinalization = try #require(system.getStaticMethodID(name: "runFinalization", sig: "()V"))
        for _ in 0..<10 {
            try system.callStatic(method: gc, options: [], args: [])
            try system.callStatic(method: runFinalization, options: [], args: [])
            Thread.sleep(forTimeInterval: 0.1)
        }

        let collected = JNI.jni.withEnv { $0.IsSameObject($1, weakPeer, nil) == JNI_TRUE }
        // stop before touching the dangling AAssetManager, which would abort the whole test process
        try #require(!collected, "Java AssetManager was garbage collected while AndroidAssetManager still referenced it")
        #expect(assetManager.listAssets(inDirectory: "") != nil)
    }

    /// Returns an `AndroidAssetManager` for a new Java AssetManager that no Java object outlives this call,
    /// along with a weak global reference for observing whether the Java AssetManager was collected.
    private static func createAssetManagerOnlyReferencedFromNative() throws -> (AndroidAssetManager, JavaObjectPointer) {
        let context = try AndroidContext.application
        let contextClass = try JClass(name: "android/content/Context", systemClass: true)
        let resourcesClass = try JClass(name: "android/content/res/Resources", systemClass: true)
        let configurationClass = try JClass(name: "android/content/res/Configuration", systemClass: true)
        let getResources = try #require(contextClass.getMethodID(name: "getResources", sig: "()Landroid/content/res/Resources;"))
        let getAssets = try #require(resourcesClass.getMethodID(name: "getAssets", sig: "()Landroid/content/res/AssetManager;"))

        return try JNI.jni.withEnv { jni, env in
            // pop every local reference created here, so only native code can keep the new AssetManager alive
            try #require(jni.PushLocalFrame(env, 32) == JNI_OK)
            defer { _ = jni.PopLocalFrame(env, nil) }

            let resources: JavaObjectPointer = try context.call(method: getResources, options: [], args: [])
            let appAssets: JavaObjectPointer = try JObject(resources).call(method: getAssets, options: [], args: [])
            let appConfiguration: JavaObjectPointer = try JObject(resources).call(method: try #require(resourcesClass.getMethodID(name: "getConfiguration", sig: "()Landroid/content/res/Configuration;")), options: [], args: [])

            // a context with a distinct Configuration gets new Resources backed by a new AssetManager
            let configuration = try configurationClass.create(ctor: try #require(configurationClass.getMethodID(name: "<init>", sig: "(Landroid/content/res/Configuration;)V")), options: [], args: [JavaParameter(l: appConfiguration)])
            JObject(configuration).set(field: try #require(configurationClass.getFieldID(name: "densityDpi", sig: "I")), value: Int32(123), options: [])
            let configurationContext: JavaObjectPointer = try context.call(method: try #require(contextClass.getMethodID(name: "createConfigurationContext", sig: "(Landroid/content/res/Configuration;)Landroid/content/Context;")), options: [], args: [JavaParameter(l: configuration)])
            let configurationResources: JavaObjectPointer = try JObject(configurationContext).call(method: getResources, options: [], args: [])
            let assets: JavaObjectPointer = try JObject(configurationResources).call(method: getAssets, options: [], args: [])
            try #require(jni.IsSameObject(env, assets, appAssets) != JNI_TRUE, "expected a new AssetManager, not the application's")

            return (AndroidAssetManager(env: env, peer: assets), try #require(jni.NewWeakGlobalRef(env, assets)))
        }
    }
    #endif
}
