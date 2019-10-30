//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

class AWSS3StoragePutDataOperationTests: AWSS3StorageOperationTestBase {

    func testPutDataOperationValidationError() {
        let options = StoragePutDataRequest.Options(accessLevel: .protected)
        let request = StoragePutDataRequest(key: "", data: testData, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StoragePutDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { (event) in
            switch event {
            case .failed(let error):
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

    func testPutDataOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.identity("", "", "")

        let options = StoragePutDataRequest.Options(accessLevel: .protected)
        let request = StoragePutDataRequest(key: testKey, data: testData, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StoragePutDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { (event) in
            switch event {
            case .failed(let error):
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

    func testPutDataOperationUploadSuccess() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(())]

        let expectedUploadSource = UploadSource.data(testData)
        let metadata = ["mykey": "Value"]
        let expectedMetadata = ["x-amz-meta-mykey": "Value"]

        let options = StoragePutDataRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType)
        let request = StoragePutDataRequest(key: testKey, data: testData, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StoragePutDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .inProcess:
                inProcessInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        }

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

    func testPutDataOperationUploadFail() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageError.service("", ""))]

        let expectedUploadSource = UploadSource.data(testData)

        let options = StoragePutDataRequest.Options(accessLevel: .protected)
        let request = StoragePutDataRequest(key: testKey, data: testData, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let failInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StoragePutDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { (event) in
            switch event {
            case .failed:
                failInvoked.fulfill()
            case .inProcess:
                inProcessInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        }

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

    func testPutDataOperationMultiPartUploadSuccess() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceMultiPartUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(())]

        var testLargeDataString = "testLargeDataString"
        for _ in 1 ... 20 {
            testLargeDataString += testLargeDataString
        }
        let testLargeData = testLargeDataString.data(using: .utf8)!
        XCTAssertTrue(testLargeData.count > StoragePutDataRequest.Options.multiPartUploadSizeThreshold,
                      "Could not create data object greater than MultiPartUploadSizeThreshold")
        let expectedUploadSource = UploadSource.data(testLargeData)
        let metadata = ["mykey": "Value"]
        let expectedMetadata = ["x-amz-meta-mykey": "Value"]

        let options = StoragePutDataRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType)
        let request = StoragePutDataRequest(key: testKey, data: testLargeData, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StoragePutDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .inProcess:
                inProcessInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        }

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
