//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSS3StoragePlugin

import AWSCognitoAuthPlugin
import AWSPluginsCore
@_spi(PluginHTTPClientEngine) import AWSPluginsCore

class AWSS3StoragePluginTestBase: XCTestCase {
    static let logger = Amplify.Logging.logger(forCategory: "Storage", logLevel: .verbose)

    static let smallDataObject = Data(repeating: 0xff, count: 1_024 * 1_024 * ProcessInfo.processInfo.activeProcessorCount)
    static let largeDataObject = Data(repeating: 0xff, count: 1_024 * 1_024 * ProcessInfo.processInfo.activeProcessorCount * 4)

    static var user1: String = "integTest\(UUID().uuidString)"
    static var user2: String = "integTest\(UUID().uuidString)"
    static var password: String = "Pp123@\(UUID().uuidString)"
    static var email1 = UUID().uuidString + "@" + UUID().uuidString + ".com"
    static var email2 = UUID().uuidString + "@" + UUID().uuidString + ".com"

    static var isFirstUserSignedUp = false
    static var isSecondUserSignedUp = false

    var requestRecorder: AWSS3StoragePluginRequestRecorder!

    var useGen2Configuration: Bool {
        ProcessInfo.processInfo.arguments.contains("GEN2")
    }

    override func setUp() async throws {
        Self.logger.debug("setUp")
        self.requestRecorder = AWSS3StoragePluginRequestRecorder()
        do {
            await Amplify.reset()

            let storagePlugin = AWSS3StoragePlugin()
            storagePlugin.httpClientEngineProxy = requestRecorder
            storagePlugin.urlRequestDelegate = requestRecorder

            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: storagePlugin)
            if useGen2Configuration {
                try Amplify.configure(with: .amplifyOutputs)
            } else {
                try Amplify.configure()
            }
            if (try? await Amplify.Auth.getCurrentUser()) != nil {
                await signOut()
            }
            await signUp()
        } catch {
            XCTFail("Failed to initialize and configure Amplify \(error)")
        }
    }

    override func tearDown() async throws {
        Self.logger.debug("tearDown")
        invalidateCurrentSession()
        await Amplify.reset()
        self.requestRecorder = nil
        // `sleep` has been added here to get more consistent test runs.
        // The plugin will always create a URLSession with the same key, so we need to invalidate it first.
        // However, it needs some time to properly clean up before creating and using a new session.
        // The `sleep` helps avoid the error: "Task created in a session that has been invalidated"
        try await Task.sleep(seconds: 1)
    }

    // MARK: Common Helper functions

    func uploadData(key: String, dataString: String) async throws {
        try await uploadData(key: key, data: Data(dataString.utf8))
    }

    func uploadTask(key: String, data: Data) async -> StorageUploadDataTask? {
        Amplify.Storage.uploadData(key: key, data: data)
    }

    func downloadTask(key: String) async -> StorageDownloadDataTask? {
        Amplify.Storage.downloadData(key: key)
    }

    func uploadData(
        key: String,
        data: Data,
        options: StorageUploadDataRequest.Options? = nil
    ) async throws {
        let completeInvoked = expectation(description: "Completed is invoked")
        Task {
            let result = try await Amplify.Storage.uploadData(
                key: key,
                data: data,
                options: options
            ).value

            XCTAssertNotNil(result)
            completeInvoked.fulfill()
        }

        await fulfillment(of: [completeInvoked], timeout: 60)
    }

    func uploadData(
        path: any StoragePath,
        data: Data,
        options: StorageUploadDataRequest.Options? = nil
    ) async throws {
        let completeInvoked = expectation(description: "Completed is invoked")
        Task {
            let result = try await Amplify.Storage.uploadData(
                path: path,
                data: data,
                options: options
            ).value

            XCTAssertNotNil(result)
            completeInvoked.fulfill()
        }

        await fulfillment(of: [completeInvoked], timeout: 60)
    }

    func remove(key: String, accessLevel: StorageAccessLevel? = nil) async {
        var removeOptions: StorageRemoveRequest.Options? = nil
        if let accessLevel = accessLevel {
            removeOptions = .init(accessLevel: accessLevel)
        }

        let result = await wait(name: "Remove operation should be successful") {
            return try await Amplify.Storage.remove(key: key, options: removeOptions)
        }
        XCTAssertNotNil(result)
    }

    func getBucketFromConfig(forResource: String) throws -> String {
        let data = try TestConfigHelper.retrieve(forResource: forResource)
        let json = try JSONDecoder().decode(JSONValue.self, from: data)

        guard let bucket = json["storage"]?["plugins"]?["awsS3StoragePlugin"]?["bucket"] else {
            throw "Could not retrieve bucket from config"
        }

        guard case let .string(bucketValue) = bucket else {
            throw "bucket is not a string value"
        }

        return bucketValue
    }

    func getBucketFromAmplifyOutputs(forResource: String) throws -> String {
        let data = try TestConfigHelper.retrieve(forResource: forResource)
        let json = try JSONDecoder().decode(JSONValue.self, from: data)

        guard let bucket = json["storage"]?["bucket_name"] else {
            throw "Could not retrieve bucket from config"
        }

        guard case let .string(bucketValue) = bucket else {
            throw "bucket is not a string value"
        }

        return bucketValue
    }

    func signUp() async {
        guard !Self.isFirstUserSignedUp, !Self.isSecondUserSignedUp else {
            return
        }

        let registerFirstUserComplete = expectation(description: "register firt user completed")
        Task {
            do {
                try await AuthSignInHelper.signUpUser(username: AWSS3StoragePluginTestBase.user1,
                                                      password: AWSS3StoragePluginTestBase.password,
                                                      email: AWSS3StoragePluginTestBase.email1)
                Self.isFirstUserSignedUp = true
                registerFirstUserComplete.fulfill()
            } catch {
                XCTFail("Failed to Sign up user: \(error)")
                registerFirstUserComplete.fulfill()
            }
        }

        let registerSecondUserComplete = expectation(description: "register second user completed")
        Task {
            do {
                try await AuthSignInHelper.signUpUser(username: AWSS3StoragePluginTestBase.user2,
                                                      password: AWSS3StoragePluginTestBase.password,
                                                      email: AWSS3StoragePluginTestBase.email2)
                Self.isSecondUserSignedUp = true
                registerSecondUserComplete.fulfill()
            } catch {
                XCTFail("Failed to Sign up user: \(error)")
                registerSecondUserComplete.fulfill()
            }
        }

        await fulfillment(of: [registerFirstUserComplete, registerSecondUserComplete],
                                  timeout: TestCommonConstants.networkTimeout)
    }

    func getURL(key: String, options: StorageGetURLRequest.Options? = nil) async -> URL? {
        return await wait(name: "Get URL completed", timeout: TestCommonConstants.networkTimeout) {
            return try await Amplify.Storage.getURL(key: key, options: options)
        }
    }

    func signOut() async {
        await wait(name: "Sign out completed") {
            await Amplify.Auth.signOut()
        }
    }

    func wait(timeout: TimeInterval = 10, closure: @escaping () async throws -> ()) async {
        let expectation = expectation(description: "Tasks completed")
        Task {
            defer { expectation.fulfill() }
            do {
                try await closure()
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }

        await fulfillment(of: [expectation], timeout: timeout)
    }

    private func invalidateCurrentSession() {
        Self.logger.debug("Invalidating URLSession")
        guard let plugin = try? Amplify.Storage.getPlugin(for: "awsS3StoragePlugin") as? AWSS3StoragePlugin else {
            print("Unable to to cast to AWSS3StoragePlugin")
            return
        }

        for serviceBehaviour in plugin.storageServicesByBucket.values {
            guard let service = serviceBehaviour as? AWSS3StorageService else {
                continue
            }
            if let delegate = service.urlSession.delegate as? StorageServiceSessionDelegate {
                delegate.storageService = nil
            }
            service.urlSession.invalidateAndCancel()
        }
    }
}
