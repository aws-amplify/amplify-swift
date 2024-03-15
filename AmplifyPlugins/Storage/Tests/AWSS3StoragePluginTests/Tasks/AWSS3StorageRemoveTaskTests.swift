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

    func testRemoveTaskSuccess() async throws {
        let serviceMock = MockAWSS3StorageService()
        let client = serviceMock.client as! MockS3Client
        client.deleteObjectHandler = { input in
            return .init()
        }

        let request = StorageRemoveRequest(
            path: StringStoragePath.fromString("/path"), options: .init())
        let task = AWSS3StorageRemoveTask(
            request,
            storageConfiguration: AWSS3StoragePluginConfiguration(),
            storageBehaviour: serviceMock)
        let value = try await task.value
        XCTAssertNotNil(value)
    }

    func testRemoveTaskNoBucket() async throws {
        let serviceMock = MockAWSS3StorageService()
        let client = serviceMock.client as! MockS3Client
        client.deleteObjectHandler = { input in
            throw AWSS3.NoSuchBucket()
        }

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
            XCTAssertTrue(error is AWSS3.NoSuchBucket)
        }
    }

}
