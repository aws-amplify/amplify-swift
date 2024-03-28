//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSS3StoragePlugin
@testable import AWSPluginsTestCommon
import AWSS3

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
            path: StringStoragePath.fromString(somePath), options: .init())
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock)
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
            path: StringStoragePath.fromString(somePath), options: .init())
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock)
        do {
            _ = try await task.value
            XCTFail("Task should throw an exception")
        }
        catch {
            guard let storageError = error as? StorageError,
                  case .service(_, _, let underlyingError) = storageError else {
                XCTFail("Should throw a Storage service error, instead threw \(error)")
                return
            }
            XCTAssertTrue(underlyingError is AWSS3.NotFound,
                          "Underlying error should be NoSuchKey, instead got \(String(describing: underlyingError))")
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
            path: StringStoragePath.fromString(somePath), options: .init())
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock)
        do {
            _ = try await task.value
            XCTFail("Task should throw an exception")
        }
        catch {
            guard let storageError = error as? StorageError,
                  case .validation(let field, _, _, _) = storageError else {
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
            path: StringStoragePath.fromString(emptyPath), options: .init())
        let task = AWSS3StorageGetURLTask(
            request,
            storageBehaviour: serviceMock)
        do {
            _ = try await task.value
            XCTFail("Task should throw an exception")
        }
        catch {
            guard let storageError = error as? StorageError,
                  case .validation(let field, _, _, _) = storageError else {
                XCTFail("Should throw a storage validation error, instead threw \(error)")
                return
            }

            XCTAssertEqual(field, "path", "Field in error should be `path`")
        }
    }
}
