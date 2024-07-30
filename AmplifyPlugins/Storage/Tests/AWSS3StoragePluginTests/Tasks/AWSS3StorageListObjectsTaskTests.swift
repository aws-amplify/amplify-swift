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
        XCTAssertTrue(value.excludedSubpaths.isEmpty)
        XCTAssertEqual(value.nextToken, "continuationToken")
        XCTAssertEqual(value.items[0].eTag, "tag")
        XCTAssertEqual(value.items[0].key, "key")
        XCTAssertEqual(value.items[0].path, "key")
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

    /// - Given: A configured Storage ListObjects Task with invalid path
    /// - When: AWSS3StorageListObjectsTask value is invoked
    /// - Then: A storage validation error should be returned
    func testListObjectsTaskWithInvalidEmptyPath() async throws {
        let serviceMock = MockAWSS3StorageService()

        let request = StorageListRequest(
            path: StringStoragePath.fromString(" "), options: .init())
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

    /// - Given: A configured Storage List Objects Task with mocked service
    /// - When: AWSS3StorageListObjectsTask value is invoked with subpathStrategy set to .exclude
    /// - Then: The delimiter should be set, the list of excluded subpaths and the list of items should be populated
    func testListObjectsTask_withSubpathStrategyExclude_shouldSucceed() async throws {
        let serviceMock = MockAWSS3StorageService()
        let client = serviceMock.client as! MockS3Client
        client.listObjectsV2Handler = { input in
            XCTAssertNotNil(input.delimiter, "Expected delimiter to be set")
            return .init(
                commonPrefixes: [
                    .init(prefix: "path/subpath1/"),
                    .init(prefix: "path/subpath2/")
                ],
                contents: [
                    .init(eTag: "tag", key: "path/result", lastModified: Date())
                ],
                nextContinuationToken: "continuationToken"
            )
        }

        let request = StorageListRequest(
            path: StringStoragePath.fromString("path/"),
            options: .init(
                subpathStrategy: .exclude
            )
        )
        let task = AWSS3StorageListObjectsTask(
            request,
            storageConfiguration: AWSS3StoragePluginConfiguration(),
            storageBehaviour: serviceMock
        )
        let value = try await task.value
        XCTAssertEqual(value.items.count, 1)
        XCTAssertEqual(value.items[0].eTag, "tag")
        XCTAssertEqual(value.items[0].path, "path/result")
        XCTAssertNotNil(value.items[0].lastModified)
        XCTAssertEqual(value.excludedSubpaths.count, 2)
        XCTAssertEqual(value.excludedSubpaths[0], "path/subpath1/")
        XCTAssertEqual(value.excludedSubpaths[1], "path/subpath2/")
        XCTAssertEqual(value.nextToken, "continuationToken")
    }

    /// - Given: A configured Storage List Objects Task with mocked service
    /// - When: AWSS3StorageListObjectsTask value is invoked with subpathStrategy set to .include
    /// - Then: The delimiter should not be set, the list of excluded subpaths should be empty and the list of items should be populated
    func testListObjectsTask_withSubpathStrategyInclude_shouldSucceed() async throws {
        let serviceMock = MockAWSS3StorageService()
        let client = serviceMock.client as! MockS3Client
        client.listObjectsV2Handler = { input in
            XCTAssertNil(input.delimiter, "Expected delimiter to be nil")
            return .init(
                contents: [
                    .init(eTag: "tag", key: "path", lastModified: Date()),
                ],
                nextContinuationToken: "continuationToken"
            )
        }

        let request = StorageListRequest(
            path: StringStoragePath.fromString("path"), 
            options: .init(
                subpathStrategy: .include
            )
        )
        let task = AWSS3StorageListObjectsTask(
            request,
            storageConfiguration: AWSS3StoragePluginConfiguration(),
            storageBehaviour: serviceMock)
        let value = try await task.value
        XCTAssertEqual(value.items.count, 1)
        XCTAssertEqual(value.items[0].eTag, "tag")
        XCTAssertEqual(value.items[0].path, "path")
        XCTAssertNotNil(value.items[0].lastModified)
        XCTAssertTrue(value.excludedSubpaths.isEmpty)
        XCTAssertEqual(value.nextToken, "continuationToken")
    }
}
