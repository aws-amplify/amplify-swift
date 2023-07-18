////
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSS3StoragePlugin
@testable import AmplifyTestCommon
@testable import AWSPluginsTestCommon

import Amplify
import XCTest

final class AWSS3StoragePluginGetPresignedUrlTests: XCTestCase {

    var systemUnderTest: AWSS3StoragePlugin!
    var storageService: MockAWSS3StorageService!
    var authService: MockAWSAuthService!
    var testKey: String!
    var testURL: URL!
    var testData: Data!
    var queue: OperationQueue!

    let defaultAccessLevel: StorageAccessLevel = .guest

    override func setUpWithError() throws {
        storageService = MockAWSS3StorageService()
        authService = MockAWSAuthService()
        testKey = UUID().uuidString
        testURL = URL(fileURLWithPath: NSTemporaryDirectory().appendingPathComponent(UUID().uuidString))
        testData = Data(UUID().uuidString.utf8)
        queue = OperationQueue()
        systemUnderTest = AWSS3StoragePlugin()
        systemUnderTest.configure(storageService: storageService,
                                  authService: authService,
                                  defaultAccessLevel: defaultAccessLevel,
                                  queue: queue)
        let url = try XCTUnwrap(testURL)
        storageService.getPreSignedURLHandler = { (_, _, _) in
            return url
        }
    }

    override func tearDownWithError() throws {
        queue.cancelAllOperations()

        storageService = nil
        authService = nil
        testKey = nil
        testURL = nil
        testData = nil
        queue = nil
        systemUnderTest = nil
    }

    /// - Given: A valid object key
    /// - When: An attempt to generate a pre-signed URL for it is performed
    /// - Then: The underlying auth service and storage services are used to build it
    func testPluginGetURLAsync() async throws {
        let output = try await systemUnderTest.getURL(key: testKey, options: nil)
        XCTAssertEqual(testURL, output)
        XCTAssertEqual(authService.interactions, [
            "getIdentityID()"
        ])
        let expectedServiceKey = "public/" + testKey
        XCTAssertEqual(storageService.interactions, [
            "getPreSignedURL(serviceKey:signingOperation:expires:) \(expectedServiceKey) getObject 18000"
        ])
    }
    
    /// - Given: An empty string as an object key
    /// - When: An attempt to generate a pre-signed URL for it is performed
    /// - Then: A StorageError.validation is thrown
    func testGetURLOperationValidationError() async throws {
        let options = StorageGetURLRequest.Options(expires: 0)
        do {
            _ = try await systemUnderTest.getURL(key: "", options: options)
            XCTFail("Expecting error")
        } catch StorageError.validation(let field, let description, let recovery, _){
            XCTAssertEqual(field, "key")
            XCTAssertEqual(recovery, "Specify a non-empty key.")
            XCTAssertEqual(description, "The `key` is specified but is empty.")
        }
    }

    /// - Given: An auth service in an invalid state
    /// - When: An attempt to generate a pre-signed URL is performed
    /// - Then: A StorageError.authError is thrown
    func testGetURLOperationGetIdentityIdError() async throws {
        let authError = AuthError.service(UUID().uuidString, UUID().uuidString, UUID().uuidString)
        authService.getIdentityIdError = authError
        let testExpires = Int(Date.distantFuture.timeIntervalSince1970)
        let options = StorageGetURLRequest.Options(expires: testExpires)

        do {
            _ = try await systemUnderTest.getURL(key: testKey, options: options)
            XCTFail("Expecting error")
        } catch StorageError.authError(let description, let recovery, _) {
            XCTAssertEqual(description, authError.errorDescription)
            XCTAssertEqual(recovery, authError.recoverySuggestion)
        }
    }

    /// - Given: A newly-configured storage plugin
    /// - When: An attempt to generate a pre-signed URL is performed using a `protected` access level
    /// - Then: A service key with `protected` in its path is passed to the storage service to generate the URL
    func testGetOperationGetPresignedURL() async throws {
        let testIdentityId = UUID().uuidString
        authService.identityId = testIdentityId
        let expectedExpires = Int.random(in: 100..<200)

        let options = StorageGetURLRequest.Options(accessLevel: .protected, expires: expectedExpires)
        let output = try await systemUnderTest.getURL(key: testKey, options: options)

        XCTAssertEqual(testURL, output)
        XCTAssertEqual(authService.interactions, [
            "getIdentityID()"
        ])

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        XCTAssertEqual(storageService.interactions, [
            "getPreSignedURL(serviceKey:signingOperation:expires:) \(expectedServiceKey) getObject \(expectedExpires)"
        ])
    }

    /// - Given: An storage service in an invalid state
    /// - When: An attempt to generate a pre-signed URL is performed
    /// - Then: A StorageError.service is thrown
    func testGetOperationGetPresignedURLFailed() async throws {
        let testIdentityId = UUID().uuidString
        authService.identityId = testIdentityId

        let error = StorageError.service(UUID().uuidString, UUID().uuidString)
        storageService.getPreSignedURLHandler = { (_,_,_) in
            throw error
        }

        let expectedExpires = 100
        let options = StorageGetURLRequest.Options(accessLevel: .protected, expires: expectedExpires)
        do {
            _ = try await systemUnderTest.getURL(key: testKey, options: options)
            XCTFail("Expecting error")
        } catch StorageError.service(let description, let suggestion, _) {
            XCTAssertEqual(description, error.errorDescription)
            XCTAssertEqual(suggestion, error.recoverySuggestion)
        }

        XCTAssertEqual(authService.interactions, [
            "getIdentityID()"
        ])

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        XCTAssertEqual(storageService.interactions, [
            "getPreSignedURL(serviceKey:signingOperation:expires:) \(expectedServiceKey) getObject \(expectedExpires)"
        ])
    }

    /// - Given: A newly-configured storage plugin
    /// - When: An attempt to generate a pre-signed URL is performed using a `targetIdentityId` value
    /// - Then: A service key with that includes the given identity in its path is passed to the storage service to generate the URL
    func testGetOperationGetPresignedURLFromTargetIdentityId() async throws {
        let testIdentityId = UUID().uuidString
        authService.identityId = testIdentityId

        let options = StorageGetURLRequest.Options(accessLevel: .protected, targetIdentityId: testIdentityId)
        let output = try await systemUnderTest.getURL(key: testKey, options: options)
        XCTAssertEqual(testURL, output)
        XCTAssertEqual(authService.interactions, [
            "getIdentityID()"
        ])

        let expectedExpires = 18000
        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        XCTAssertEqual(storageService.interactions, [
            "getPreSignedURL(serviceKey:signingOperation:expires:) \(expectedServiceKey) getObject \(expectedExpires)"
        ])
    }

    /// - Given: A key to a non-existent S3 object
    /// - When: An attempt to generate a pre-signed URL is performed using the `validateObjectExistence` option
    /// - Then: The plugin throws an AmplifyStorageError.notFound error
    func testGetURLNonExistentKeyWithValidateObjectExistenceOption() async throws {
        storageService.validateObjectExistenceHandler = { key in
            throw StorageError.keyNotFound(key, "", "")
        }
        let nonExistentKey = UUID().uuidString
        let options = StorageGetURLRequest.Options(
            pluginOptions: AWSStorageGetURLOptions(
                validateObjectExistence: true
            )
        )
        do {
            let url = try await systemUnderTest.getURL(key: nonExistentKey, options: options)
            XCTFail("Expecting error but got url: \(url)")
        } catch StorageError.keyNotFound(let key, _, _, _) {
            XCTAssertTrue(key.contains(nonExistentKey), "nonExistentKey: \(nonExistentKey), key: \(key)")
        }
    }

    /// - Given: A key to a non-existent S3 object
    /// - When: An attempt to generate a pre-signed URL is performed without using the `validateObjectExistence` option
    /// - Then: The plugin returns without an error
    func testGetURLNonExistentKeyWithoutValidateObjectExistenceOption() async throws {
        storageService.validateObjectExistenceHandler = { key in
            throw StorageError.keyNotFound(key, "", "")
        }
        let nonExistentKey = UUID().uuidString
        let options = StorageGetURLRequest.Options(
            pluginOptions: AWSStorageGetURLOptions(
                validateObjectExistence: false
            )
        )
        _ = try await systemUnderTest.getURL(key: nonExistentKey, options: options)
    }
}
