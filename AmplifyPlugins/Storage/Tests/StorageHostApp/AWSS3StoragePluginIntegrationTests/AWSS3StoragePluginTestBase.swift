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

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSS3StoragePluginTestBase: XCTestCase, @unchecked Sendable {
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
        requestRecorder = AWSS3StoragePluginRequestRecorder()
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
            if await (try? Amplify.Auth.getCurrentUser()) != nil {
                await signOut()
            }
            await signUp()
        } catch {
            XCTFail("Failed to initialize and configure Amplify \(error)")
        }
    }

    override func tearDown() async throws {
        Self.logger.debug("tearDown")
        await invalidateCurrentSession()
        await Amplify.reset()
        requestRecorder = nil
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
        if let accessLevel {
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
                try await AuthSignInHelper.signUpUser(
                    username: AWSS3StoragePluginTestBase.user1,
                    password: AWSS3StoragePluginTestBase.password,
                    email: AWSS3StoragePluginTestBase.email1
                )
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
                try await AuthSignInHelper.signUpUser(
                    username: AWSS3StoragePluginTestBase.user2,
                    password: AWSS3StoragePluginTestBase.password,
                    email: AWSS3StoragePluginTestBase.email2
                )
                Self.isSecondUserSignedUp = true
                registerSecondUserComplete.fulfill()
            } catch {
                XCTFail("Failed to Sign up user: \(error)")
                registerSecondUserComplete.fulfill()
            }
        }

        await fulfillment(
            of: [registerFirstUserComplete, registerSecondUserComplete],
            timeout: TestCommonConstants.networkTimeout
        )
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

    func wait(timeout: TimeInterval = 10, closure: @escaping () async throws -> Void) async {
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

    /// Invalidates every storage service's background `URLSession` and awaits actual teardown before
    /// the next test recreates one with the same fixed identifier ("Task created in a session that has
    /// been invalidated"). Waits on the delegate's `StorageURLSessionDidBecomeInvalidNotification`.
    private func invalidateCurrentSession() async {
        Self.logger.debug("Invalidating URLSession")
        guard let plugin = try? Amplify.Storage.getPlugin(for: "awsS3StoragePlugin") as? AWSS3StoragePlugin else {
            print("Unable to to cast to AWSS3StoragePlugin")
            return
        }

        let sessions = plugin.storageServicesByBucket.values
            .compactMap { $0 as? AWSS3StorageService }
            .map { service -> URLSession in
                // Detach so invalidation doesn't trigger resetURLSession() and recreate the session.
                if let delegate = service.urlSession.delegate as? StorageServiceSessionDelegate {
                    delegate.storageService = nil
                }
                return service.urlSession
            }

        await withTaskGroup(of: Void.self) { group in
            for session in sessions {
                group.addTask {
                    await Self.awaitInvalidation(of: session, timeout: 10)
                }
            }
        }
    }

    /// Invalidates `session`, resuming when it becomes invalid or after `timeout`, whichever is first.
    private static func awaitInvalidation(of session: URLSession, timeout: TimeInterval) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let lock = NSLock()
            var didResume = false
            var observer: NSObjectProtocol?

            func finish() {
                lock.lock()
                let shouldResume = !didResume
                didResume = true
                lock.unlock()
                guard shouldResume else { return }
                if let observer {
                    NotificationCenter.default.removeObserver(observer)
                }
                continuation.resume()
            }

            // Register before invalidating so the completion notification cannot be missed.
            observer = NotificationCenter.default.addObserver(
                forName: .StorageURLSessionDidBecomeInvalidNotification,
                object: session,
                queue: nil
            ) { _ in finish() }

            session.invalidateAndCancel()

            // Fallback so teardown never hangs if the notification does not arrive.
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { finish() }
        }
    }
}
