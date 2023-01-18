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

final class StorageStressTests: XCTestCase {

    static let logger = Amplify.Logging.logger(forCategory: "Storage", logLevel: .verbose)
    static let amplifyConfiguration = "testconfiguration/AWSAmplifyStressTests-amplifyconfiguration"
    
    let smallDataObjectForStressTest = Data(repeating: 0xff, count: 1_024 * 1_024) // 1MB
    let largeDataObjectForStressTest = Data(repeating: 0xff, count: 1_024 * 1_024 * 100) // 100MB
    let concurrencyLimit = 10
    
    static var user1: String = "integTest\(UUID().uuidString)"
    static var user2: String = "integTest\(UUID().uuidString)"
    static var password: String = "P123@\(UUID().uuidString)"
    static var email1 = UUID().uuidString + "@" + UUID().uuidString + ".com"
    static var email2 = UUID().uuidString + "@" + UUID().uuidString + ".com"

    static var isFirstUserSignedUp = false
    static var isSecondUserSignedUp = false

    override func setUp() async throws {
        Self.logger.debug("setUp")
        do {
            await Amplify.reset()
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
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
        // `sleep` has been added here to get more consistent test runs.
        // The plugin will always create a URLSession with the same key, so we need to invalidate it first.
        // However, it needs some time to properly clean up before creating and using a new session.
        // The `sleep` helps avoid the error: "Task created in a session that has been invalidated"
        try await Task.sleep(seconds: 1)
    }
    // MARK: - Stress tests
    
    /// Given: A small data object
    /// When: Upload the data simultaneously from 10 tasks
    /// Then: The operation completes successfully
    func testUploadMultipleSmallDataObjects() async {
        let uploadExpectation = asyncExpectation(description: "Small data object uploaded successfully",
                                    expectedFulfillmentCount: concurrencyLimit)
        let removeExpectation = asyncExpectation(description: "Data object removed successfully",
                                          expectedFulfillmentCount: concurrencyLimit)
        for _ in 1...concurrencyLimit {
            Task {
                do {
                    let key = UUID().uuidString
                    let uploadKey = try await Amplify.Storage.uploadData(key: key,
                                                                         data: smallDataObjectForStressTest,
                                                                         options: nil).value
                    XCTAssertEqual(uploadKey, key)
                    await uploadExpectation.fulfill()
                    
                    try await Amplify.Storage.remove(key: key)
                    await removeExpectation.fulfill()
                } catch {
                    XCTFail("Error: \(error)")
                }
            }
        }
        
        await waitForExpectations([uploadExpectation, removeExpectation], timeout: 60)
    }
    
    /// Given: A very large data object(100MB)
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadLargeDataObject() async {
        let uploadExpectation = asyncExpectation(description: "Large data object uploaded successfully")
        let removeExpectation = asyncExpectation(description: "Data object removed successfully")
        do {
            let key = UUID().uuidString
            let uploadKey = try await Amplify.Storage.uploadData(key: key,
                                                                 data: largeDataObjectForStressTest,
                                                                 options: nil).value
            XCTAssertEqual(uploadKey, key)
            await uploadExpectation.fulfill()
            
            try await Amplify.Storage.remove(key: key)
            await removeExpectation.fulfill()
        } catch {
            XCTFail("Error: \(error)")
        }
        await waitForExpectations([uploadExpectation, removeExpectation], timeout: 180)
    }
    
    /// Given: An object in storage
    /// When: Object is downloaded simultaneously from 10 tasks
    /// Then: The operation completes successfully with the data retrieved
    func testDownloadMultipleSmallDataObjects() async {
        let downloadExpectation = asyncExpectation(description: "Data object downloaded successfully",
                                    expectedFulfillmentCount: concurrencyLimit)
        let uploadExpectation = asyncExpectation(description: "Data object uploaded successfully",
                                    expectedFulfillmentCount: concurrencyLimit)
        let removeExpectation = asyncExpectation(description: "Data object removed successfully",
                                          expectedFulfillmentCount: concurrencyLimit)
        for _ in 1...concurrencyLimit {
            Task {
                let key = UUID().uuidString
                let uploadKey = try await Amplify.Storage.uploadData(key: key,
                                                                     data: smallDataObjectForStressTest,
                                                                     options: nil).value
                XCTAssertEqual(uploadKey, key)
                await uploadExpectation.fulfill()
                
                let _ = try await Amplify.Storage.downloadData(key: key, options: .init()).value
                await downloadExpectation.fulfill()
                
                try await Amplify.Storage.remove(key: key)
                await removeExpectation.fulfill()
            }
        }
        
        await waitForExpectations([downloadExpectation, uploadExpectation, removeExpectation], timeout: 60)
    }
    
    /// Given: A very large data object(100MB) in storage
    /// When: Download the data
    /// Then: The operation completes successfully
    func testDownloadLargeDataObject() async {
        let downloadExpectation = asyncExpectation(description: "Data object downloaded successfully")
        let uploadExpectation = asyncExpectation(description: "Data object uploaded successfully")
        let removeExpectation = asyncExpectation(description: "Data object removed successfully")
        do {
            let key = UUID().uuidString
            let uploadKey = try await Amplify.Storage.uploadData(key: key,
                                                                 data: largeDataObjectForStressTest,
                                                                 options: nil).value
            XCTAssertEqual(uploadKey, key)
            await uploadExpectation.fulfill()
            
            let _ = try await Amplify.Storage.downloadData(key: key, options: .init()).value
            await downloadExpectation.fulfill()
            
            try await Amplify.Storage.remove(key: key)
            await removeExpectation.fulfill()
        } catch {
            XCTFail("Error: \(error)")
        }
        await waitForExpectations([uploadExpectation, removeExpectation], timeout: 180)
    }

    
    // MARK: - Helper Functions
    
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

    func signOut() async {
        await wait(name: "Sign out completed") {
            await Amplify.Auth.signOut()
        }
    }

    private func invalidateCurrentSession() {
        Self.logger.debug("Invalidating URLSession")
        guard let plugin = try? Amplify.Storage.getPlugin(for: "awsS3StoragePlugin") as? AWSS3StoragePlugin,
              let service = plugin.storageService as? AWSS3StorageService else {
            print("Unable to to cast to AWSS3StorageService")
            return
        }

        if let delegate = service.urlSession.delegate as? StorageServiceSessionDelegate {
            delegate.storageService = nil
        }
        service.urlSession.invalidateAndCancel()
    }
}
