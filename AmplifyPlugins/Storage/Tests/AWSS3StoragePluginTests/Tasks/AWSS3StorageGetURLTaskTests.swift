//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSPluginsTestCommon
@testable import AWSS3StoragePlugin

class AWSS3StorageGetURLTaskTests: XCTestCase {


    /// - Given: A configured Storage GetURL Task with mocked service
    /// - When: AWSS3StorageGetURLTask value is invoked
    /// - Then: A URL should be returned.
    func testGetURLTaskSuccess() async throws {

        let somePath = "path"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

        let serviceMock = MockAWSS3StorageService()
        serviceMock.getPreSignedURLHandler = { path, _, _ in
            XCTAssertEqual(somePath, path)
            return tempURL
        }

        let request = StorageGetURLRequest(
            path: StringStoragePath.fromString(somePath), options: .init()
        )
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock
        )
        let value = try await task.value
        XCTAssertEqual(value, tempURL)
    }

    /// - Given: A configured Storage GetURL Task with mocked service, throwing `NotFound` exception
    /// - When: AWSS3StorageGetURLTask value is invoked
    /// - Then: A storage service error should be returned, with an underlying service error
    func testGetURLTaskNoBucket() async throws {
        let somePath = "path"

        let serviceMock = MockAWSS3StorageService()
        serviceMock.getPreSignedURLHandler = { _, _, _ in
            throw AWSS3.NotFound()
        }

        let request = StorageGetURLRequest(
            path: StringStoragePath.fromString(somePath), options: .init()
        )
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock
        )
        do {
            _ = try await task.value
            XCTFail("Task should throw an exception")
        } catch {
            guard let storageError = error as? StorageError,
                  case .service(_, _, let underlyingError) = storageError
            else {
                XCTFail("Should throw a Storage service error, instead threw \(error)")
                return
            }
            XCTAssertTrue(
                underlyingError is AWSS3.NotFound,
                "Underlying error should be NoSuchKey, instead got \(String(describing: underlyingError))"
            )
        }
    }

    /// - Given: A configured Storage GetURL Task with invalid path
    /// - When: AWSS3StorageGetURLTask value is invoked
    /// - Then: A storage validation error should be returned
    func testGetURLTaskWithInvalidPath() async throws {
        let somePath = "/path"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

        let serviceMock = MockAWSS3StorageService()
        serviceMock.getPreSignedURLHandler = { path, _, _ in
            XCTAssertEqual(somePath, path)
            return tempURL
        }

        let request = StorageGetURLRequest(
            path: StringStoragePath.fromString(somePath), options: .init()
        )
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock
        )
        do {
            _ = try await task.value
            XCTFail("Task should throw an exception")
        } catch {
            guard let storageError = error as? StorageError,
                  case .validation(let field, _, _, _) = storageError
            else {
                XCTFail("Should throw a storage validation error, instead threw \(error)")
                return
            }

            XCTAssertEqual(field, "path", "Field in error should be `path`")
        }
    }

    /// - Given: A configured Storage GetURL Task with invalid path
    /// - When: AWSS3StorageGetURLTask value is invoked
    /// - Then: A storage validation error should be returned
    func testGetURLTaskWithInvalidEmptyPath() async throws {
        let emptyPath = " "
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

        let serviceMock = MockAWSS3StorageService()
        serviceMock.getPreSignedURLHandler = { path, _, _ in
            XCTAssertEqual(emptyPath, path)
            return tempURL
        }

        let request = StorageGetURLRequest(
            path: StringStoragePath.fromString(emptyPath), options: .init()
        )
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock
        )
        do {
            _ = try await task.value
            XCTFail("Task should throw an exception")
        } catch {
            guard let storageError = error as? StorageError,
                  case .validation(let field, _, _, _) = storageError
            else {
                XCTFail("Should throw a storage validation error, instead threw \(error)")
                return
            }

            XCTAssertEqual(field, "path", "Field in error should be `path`")
        }
    }

    /// - Given: A configured Storage GetURL Task with PUT method and a valid path
    /// - When: AWSS3StorageGetURLTask value is invoked
    /// - Then: A URL should be returned using putObject signing operation
    /// _Requirements: 1.3_
    func testGetURLTaskWithPutMethodSuccess() async throws {
        let somePath = "path"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

        let serviceMock = MockAWSS3StorageService()
        serviceMock.getPreSignedURLHandler = { path, _, _ in
            XCTAssertEqual(somePath, path)
            return tempURL
        }

        let request = StorageGetURLRequest(
            path: StringStoragePath.fromString(somePath),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(method: .put)
            )
        )
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock
        )
        let value = try await task.value
        XCTAssertEqual(value, tempURL)

        XCTAssertEqual(serviceMock.interactions.count, 1)
        let interaction = serviceMock.interactions[0]
        XCTAssertTrue(interaction.contains("putObject"), "Should use putObject signing operation")
    }

    /// - Given: A configured Storage GetURL Task with PUT method and an empty path
    /// - When: AWSS3StorageGetURLTask value is invoked
    /// - Then: A storage validation error should be returned
    /// _Requirements: 5.1_
    func testGetURLTaskWithPutMethodAndEmptyPathThrowsValidationError() async throws {
        let emptyPath = " "
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

        let serviceMock = MockAWSS3StorageService()
        serviceMock.getPreSignedURLHandler = { _, _, _ in
            return tempURL
        }

        let request = StorageGetURLRequest(
            path: StringStoragePath.fromString(emptyPath),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(method: .put)
            )
        )
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock
        )
        do {
            _ = try await task.value
            XCTFail("Task should throw an exception")
        } catch {
            guard let storageError = error as? StorageError,
                  case .validation(let field, _, _, _) = storageError
            else {
                XCTFail("Should throw a storage validation error, instead threw \(error)")
                return
            }

            XCTAssertEqual(field, "path", "Field in error should be `path`")
        }
    }

    /// - Given: A configured Storage GetURL Task with PUT method and a contentType
    /// - When: AWSS3StorageGetURLTask value is invoked
    /// - Then: The metadata dictionary should include the content type
    /// _Requirements: 3.2_
    func testGetURLTaskWithPutMethodAndContentTypeIncludesMetadata() async throws {
        let somePath = "path"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let expectedContentType = "image/png"

        let serviceMock = MockAWSS3StorageService()
        serviceMock.getPreSignedURLHandler = { _, _, _ in
            return tempURL
        }

        let request = StorageGetURLRequest(
            path: StringStoragePath.fromString(somePath),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(
                    method: .put,
                    contentType: expectedContentType
                )
            )
        )
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock
        )
        let value = try await task.value
        XCTAssertEqual(value, tempURL)

        XCTAssertEqual(serviceMock.interactions.count, 1)
        let interaction = serviceMock.interactions[0]
        XCTAssertTrue(interaction.contains("putObject"), "Should use putObject signing operation")
        XCTAssertTrue(
            interaction.contains("Content-Type"),
            "Metadata should contain Content-Type"
        )
        XCTAssertTrue(
            interaction.contains(expectedContentType),
            "Metadata should contain the expected content type value"
        )
    }

    /// - Given: A configured Storage GetURL Task with GET method and a contentType
    /// - When: AWSS3StorageGetURLTask value is invoked
    /// - Then: The metadata should be nil (contentType is ignored for GET)
    /// _Requirements: 3.3_
    func testGetURLTaskWithGetMethodAndContentTypeIgnoresMetadata() async throws {
        let somePath = "path"
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

        let serviceMock = MockAWSS3StorageService()
        serviceMock.getPreSignedURLHandler = { _, _, _ in
            return tempURL
        }

        let request = StorageGetURLRequest(
            path: StringStoragePath.fromString(somePath),
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(
                    method: .get,
                    contentType: "application/json"
                )
            )
        )
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock
        )
        let value = try await task.value
        XCTAssertEqual(value, tempURL)

        XCTAssertEqual(serviceMock.interactions.count, 1)
        let interaction = serviceMock.interactions[0]
        XCTAssertTrue(interaction.contains("getObject"), "Should use getObject signing operation")
        XCTAssertTrue(interaction.contains("nil"), "Metadata should be nil for GET method even when contentType is provided")
    }
}
