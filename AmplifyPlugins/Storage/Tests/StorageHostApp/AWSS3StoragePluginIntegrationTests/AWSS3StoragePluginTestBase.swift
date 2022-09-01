//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
import AWSS3StoragePlugin
import AmplifyAsyncTesting
import AWSCognitoAuthPlugin

class AWSS3StoragePluginTestBase: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/AWSS3StoragePluginTests-amplifyconfiguration"

    static let largeDataObject = Data(repeating: 0xff, count: 1_024 * 1_024 * 6) // 6MB

    static var user1: String = "integTest\(UUID().uuidString)"
    static var user2: String = "integTest\(UUID().uuidString)"
    static var password: String = "P123@\(UUID().uuidString)"
    static var email1 = UUID().uuidString + "@" + UUID().uuidString + ".com"
    static var email2 = UUID().uuidString + "@" + UUID().uuidString + ".com"

    static var isFirstUserSignedUp = false
    static var isSecondUserSignedUp = false

    override func setUp() async throws {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
            await signUp()
        } catch {
            XCTFail("Failed to initialize and configure Amplify \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
        // Unforunately, `sleep` has been added here to get more consistent test runs. The SDK will be used with
        // same key to create a URLSession. The `sleep` helps avoid the error:
        // ```
        // A background URLSession with identifier
        // com.amazonaws.AWSS3TransferUtility.Default.Identifier.awsS3StoragePlugin already exists!`
        // ```
        // TODO: Remove in the future when the plugin no longer depends on the SDK and have addressed this problem.
        sleep(5)
    }

    // MARK: Common Helper functions

    func uploadData(key: String, dataString: String) async {
        await uploadData(key: key, data: dataString.data(using: .utf8)!)
    }

    func uploadData(key: String, data: Data) async {
        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        await wait(with: completeInvoked, timeout: 60) {
            _ = try await Amplify.Storage.uploadData(key: key, data: data, options: nil).value
        }
    }

    static func getBucketFromConfig(forResource: String) throws -> String {
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

    func signUp() async {
        guard !Self.isFirstUserSignedUp, !Self.isSecondUserSignedUp else {
            return
        }

        let registerFirstUserComplete = asyncExpectation(description: "register firt user completed")
        Task {
            do {
                try await AuthSignInHelper.signUpUser(username: AWSS3StoragePluginTestBase.user1,
                                                      password: AWSS3StoragePluginTestBase.password,
                                                      email: AWSS3StoragePluginTestBase.email1)
                Self.isFirstUserSignedUp = true
                await registerFirstUserComplete.fulfill()
            } catch {
                XCTFail("Failed to Sign up user: \(error)")
                await registerFirstUserComplete.fulfill()
            }
        }

        let registerSecondUserComplete = asyncExpectation(description: "register second user completed")
        Task {
            do {
                try await AuthSignInHelper.signUpUser(username: AWSS3StoragePluginTestBase.user2,
                                                      password: AWSS3StoragePluginTestBase.password,
                                                      email: AWSS3StoragePluginTestBase.email2)
                Self.isSecondUserSignedUp = true
                await registerSecondUserComplete.fulfill()
            } catch {
                XCTFail("Failed to Sign up user: \(error)")
                await registerSecondUserComplete.fulfill()
            }
        }

        await waitForExpectations([registerFirstUserComplete, registerSecondUserComplete],
                                  timeout: TestCommonConstants.networkTimeout)
    }

    func getURL(key: String, options: StorageGetURLRequest.Options? = nil) async -> URL? {
        return await wait(name: "Get URL completed", timeout: TestCommonConstants.networkTimeout) {
            return try await Amplify.Storage.getURL(key: key, options: options)
        }
    }

    // MARK: - Async Testing Helpers
    @discardableResult
    func wait<T>(with expectation: AsyncExpectation,
                 timeout: TimeInterval = TestCommonConstants.networkTimeout,
                 action: @escaping () async throws -> T) async -> T? {
        let task = Task { () -> T? in
            defer {
                Task {
                    await expectation.fulfill()
                }
            }
            do {
                return try await action()
            } catch {
                if !(error is CancellationError) {
                    XCTFail("Failed with \(error)")
                }
                return nil
            }
        }
        await waitForExpectations([expectation], timeout: timeout)
        task.cancel()
        return await task.value

    }

    @discardableResult
    func wait<T>(name: String,
                 timeout: TimeInterval = TestCommonConstants.networkTimeout,
                 action: @escaping () async throws -> T) async -> T? {
        let expectation = asyncExpectation(description: name)
        return await wait(with: expectation, timeout: timeout, action: action)
    }

    @discardableResult
    func waitError<T>(with expectation: AsyncExpectation,
                      timeout: TimeInterval = TestCommonConstants.networkTimeout,
                      action: @escaping () async throws -> T) async -> Error? {
        let task = Task { () -> Error? in
            defer {
                Task {
                    await expectation.fulfill()
                }
            }
            do {
                let result = try await action()
                XCTFail("Should not have completed, got \(result)")
                return nil
            } catch {
                if error is CancellationError {
                    return nil
                }
                return error
            }
        }
        await waitForExpectations([expectation], timeout: timeout)
        task.cancel()
        return await task.value
    }

    @discardableResult
    func waitError<T>(name: String,
                      timeout: TimeInterval = TestCommonConstants.networkTimeout,
                      action: @escaping () async throws -> T) async -> Error? {
        let expectation = asyncExpectation(description: name)
        return await waitError(with: expectation, timeout: timeout, action: action)
    }
}
