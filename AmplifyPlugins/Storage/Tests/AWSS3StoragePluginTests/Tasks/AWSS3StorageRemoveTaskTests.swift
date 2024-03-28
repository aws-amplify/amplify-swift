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

class AWSS3StorageRemoveTaskTests: XCTestCase {


    /// - Given: A configured Storage Remove Task with mocked service
    /// - When: AWSS3StorageRemoveTask value is invoked
    /// - Then: A key should be returned, that has been removed without any errors.
    func testRemoveTaskSuccess() async throws {
        let serviceMock = MockAWSS3StorageService()
        let client = serviceMock.client as! MockS3Client
        client.deleteObjectHandler = { input in
            return .init()
        }

        let request = StorageRemoveRequest(
            path: StringStoragePath.fromString("path"), options: .init())
        let task = AWSS3StorageRemoveTask(
            request,
            storageConfiguration: AWSS3StoragePluginConfiguration(),
            storageBehaviour: serviceMock)
        let value = try await task.value
        XCTAssertEqual(value, "path")
    }

    /// - Given: A configured Storage Remove Task with mocked service, throwing `NoSuchKey` exception
    /// - When: AWSS3StorageRemoveTask value is invoked
    /// - Then: A storage service error should be returned, with an underlying service error
    func testRemoveTaskNoBucket() async throws {
        let serviceMock = MockAWSS3StorageService()
        let client = serviceMock.client as! MockS3Client
        client.deleteObjectHandler = { input in
            throw AWSS3.NoSuchKey()
        }

        let request = StorageRemoveRequest(
            path: StringStoragePath.fromString("path"), options: .init())
        let task = AWSS3StorageRemoveTask(
            request,
            storageConfiguration: AWSS3StoragePluginConfiguration(),
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
            XCTAssertTrue(underlyingError is AWSS3.NoSuchKey,
                          "Underlying error should be NoSuchKey, instead got \(String(describing: underlyingError))")
        }
    }

    /// - Given: A configured Storage Remove Task with invalid path
    /// - When: AWSS3StorageRemoveTask value is invoked
    /// - Then: A storage validation error should be returned
    func testRemoveTaskWithInvalidPath() async throws {
        let serviceMock = MockAWSS3StorageService()

        let request = StorageRemoveRequest(
            path: StringStoragePath.fromString("/path"), options: .init())
        let task = AWSS3StorageRemoveTask(
            request,
            storageConfiguration: AWSS3StoragePluginConfiguration(),
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

    /// - Given: A configured Storage Remove Task with invalid path
    /// - When: AWSS3StorageRemoveTask value is invoked
    /// - Then: A storage validation error should be returned
    func testRemoveTaskWithInvalidEmptyPath() async throws {
        let serviceMock = MockAWSS3StorageService()

        let request = StorageRemoveRequest(
            path: StringStoragePath.fromString(" "), options: .init())
        let task = AWSS3StorageRemoveTask(
            request,
            storageConfiguration: AWSS3StoragePluginConfiguration(),
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
