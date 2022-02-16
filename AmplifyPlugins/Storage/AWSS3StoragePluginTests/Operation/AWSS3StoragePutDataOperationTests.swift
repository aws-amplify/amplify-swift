//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSS3StoragePlugin
@testable import AWSPluginsCore
@testable import AWSPluginsTestCommon

import AWSS3

class AWSS3StorageUploadDataOperationTests: AWSS3StorageOperationTestBase {

    func testUploadDataOperationValidationError() {
        let options = StorageUploadDataRequest.Options(accessLevel: .protected)
        let request = StorageUploadDataRequest(key: "", data: testData, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(request,
                                                        storageConfiguration: testStorageConfiguration,
                                                        storageService: mockStorageService,
                                                        authService: mockAuthService,
                                                        progressListener: nil) { result in
            switch result {
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should have failed with validation error")
                    return
                }
                failedInvoked.fulfill()
            default:
                XCTFail("Should have received failed event")
            }
        }

        operation.start()

        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    func testUploadDataOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.service("", "", "")

        let options = StorageUploadDataRequest.Options(accessLevel: .protected)
        let request = StorageUploadDataRequest(key: testKey, data: testData, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(request,
                                                        storageConfiguration: testStorageConfiguration,
                                                        storageService: mockStorageService,
                                                        authService: mockAuthService,
                                                        progressListener: nil) { result in
            switch result {
            case .failure(let error):
                guard case .authError = error else {
                    XCTFail("Should have failed with authError")
                    return
                }
                failedInvoked.fulfill()
            default:
                XCTFail("Should have received failed event")
            }
        }

        operation.start()

        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    func testUploadDataOperationUploadSuccess() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completedVoid]

        let expectedUploadSource = UploadSource.data(testData)
        let metadata = ["mykey": "Value"]
        let expectedMetadata = ["x-amz-meta-mykey": "Value"]

        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType)
        let request = StorageUploadDataRequest(key: testKey, data: testData, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        })

        operation.start()

        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.uploadCalled, 1)
        mockStorageService.verifyUpload(serviceKey: expectedServiceKey,
                                        key: testKey,
                                        uploadSource: expectedUploadSource,
                                        contentType: testContentType,
                                        metadata: expectedMetadata)
    }

    func testUploadDataOperationUploadFail() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageError.service("", ""))]

        let expectedUploadSource = UploadSource.data(testData)

        let options = StorageUploadDataRequest.Options(accessLevel: .protected)
        let request = StorageUploadDataRequest(key: testKey, data: testData, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let failInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .failure:
                failInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        })

        operation.start()

        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.uploadCalled, 1)
        mockStorageService.verifyUpload(serviceKey: expectedServiceKey,
                                        key: testKey,
                                        uploadSource: expectedUploadSource,
                                        contentType: nil,
                                        metadata: nil)
    }

    func testUploadDataOperationMultiPartUploadSuccess() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceMultiPartUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completedVoid]

        var testLargeDataString = "testLargeDataString"
        for _ in 1 ... 20 {
            testLargeDataString += testLargeDataString
        }
        let testLargeData = testLargeDataString.data(using: .utf8)!
        XCTAssertTrue(testLargeData.count > StorageUploadDataRequest.Options.multiPartUploadSizeThreshold,
                      "Could not create data object greater than MultiPartUploadSizeThreshold")
        let expectedUploadSource = UploadSource.data(testLargeData)
        let metadata = ["mykey": "Value"]
        let expectedMetadata = ["x-amz-meta-mykey": "Value"]

        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType)
        let request = StorageUploadDataRequest(key: testKey, data: testLargeData, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        })

        operation.start()

        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.multiPartUploadCalled, 1)
        mockStorageService.verifyMultiPartUpload(serviceKey: expectedServiceKey,
                                                 key: testKey,
                                                 uploadSource: expectedUploadSource,
                                                 contentType: testContentType,
                                                 metadata: expectedMetadata)
    }

    // TODO: test pause, resume, canel, etc.
}
