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

class AWSS3StorageListObjectsTaskTests: XCTestCase {

    /// - Given: A configured Storage List Objects Task with mocked service
    /// - When: AWSS3StorageListObjectsTask value is invoked
    /// - Then: A list of  keys should be returned.
    func testListObjectsTaskSuccess() async throws {
        let serviceMock = MockAWSS3StorageService()
        let client = serviceMock.client as! MockS3Client
        client.listObjectsV2Handler = { input in
            return .init(
                contents: [
                    .init(eTag: "tag", key: "key", lastModified: Date()),
                    .init(eTag: "tag", key: "key", lastModified: Date())],
                nextContinuationToken: "continuationToken"
            )
        }

        let request = StorageListRequest(
            path: StringStoragePath.fromString("path"), options: .init())
        let task = AWSS3StorageListObjectsTask(
            request,
            storageConfiguration: AWSS3StoragePluginConfiguration(),
            storageBehaviour: serviceMock)
        let value = try await task.value
        XCTAssertEqual(value.items.count, 2)
        XCTAssertEqual(value.nextToken, "continuationToken")
        XCTAssertEqual(value.items[0].eTag, "tag")
        XCTAssertEqual(value.items[0].key, "key")
        XCTAssertNotNil(value.items[0].lastModified)

    }

    /// - Given: A configured ListObjects Remove Task with mocked service, throwing `NoSuchKey` exception
    /// - When: AWSS3StorageListObjectsTask value is invoked
    /// - Then: A storage service error should be returned, with an underlying service error
    func testListObjectsTaskNoBucket() async throws {
        let serviceMock = MockAWSS3StorageService()
        let client = serviceMock.client as! MockS3Client
        client.listObjectsV2Handler = { input in
            throw AWSS3.NoSuchKey()
        }

        let request = StorageListRequest(
            path: StringStoragePath.fromString("path"), options: .init())
        let task = AWSS3StorageListObjectsTask(
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

    /// - Given: A configured Storage ListObjects Task with invalid path
    /// - When: AWSS3StorageListObjectsTask value is invoked
    /// - Then: A storage validation error should be returned
    func testListObjectsTaskWithInvalidPath() async throws {
        let serviceMock = MockAWSS3StorageService()

        let request = StorageListRequest(
            path: StringStoragePath.fromString("/path"), options: .init())
        let task = AWSS3StorageListObjectsTask(
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
