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
import AWSS3

class AWSS3StoragePutOperationTests: AWSS3StorageOperationTestBase {

    func testPutOperationValidationError() {
        let options = StoragePutRequest.Options(accessLevel: .protected)
        let request = StoragePutRequest(key: "", source: .data(testData), options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StoragePutOperation(request,
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

    func testPutOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.identity("", "", "")
        
        let options = StoragePutRequest.Options(accessLevel: .protected)
        let request = StoragePutRequest(key: testKey, source: .data(testData), options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StoragePutOperation(request,
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

    func testPutOperationGetSizeForMissingFileError() {
        let url = URL(fileURLWithPath: "missingFile")
        let options = StoragePutRequest.Options(accessLevel: .protected)
        let request = StoragePutRequest(key: testKey, source: .local(url), options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StoragePutOperation(request,
                                                 storageService: mockStorageService,
                                                 authService: mockAuthService) { (event) in
            switch event {
            case .failed(let error):
                guard case .localFileNotFound = error else {
                    XCTFail("Should have failed local file not found error")
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

    func testPutOperationUploadSuccess() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(())]

        let expectedUploadSource = StoragePutRequest.Source.data(testData)
        let metadata = ["mykey": "Value"]
        let expectedMetadata = ["x-amz-meta-mykey": "Value"]

        let options = StoragePutRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType)
        let request = StoragePutRequest(key: testKey, source: expectedUploadSource, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StoragePutOperation(request,
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

    func testPutOperationUploadFail() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageError.service("", ""))]

        let expectedUploadSource = StoragePutRequest.Source.data(testData)

        let options = StoragePutRequest.Options(accessLevel: .protected)
        let request = StoragePutRequest(key: testKey, source: expectedUploadSource, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let failInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StoragePutOperation(request,
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

    func testPutOperationMultiPartUploadSuccess() {
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
        XCTAssertTrue(testLargeData.count > StoragePutRequest.Options.multiPartUploadSizeThreshold,
                      "Could not create data object greater than MultiPartUploadSizeThreshold")
        let expectedUploadSource = StoragePutRequest.Source.data(testLargeData)
        let metadata = ["mykey": "Value"]
        let expectedMetadata = ["x-amz-meta-mykey": "Value"]

        let options = StoragePutRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType)
        let request = StoragePutRequest(key: testKey, source: expectedUploadSource, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StoragePutOperation(request,
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
