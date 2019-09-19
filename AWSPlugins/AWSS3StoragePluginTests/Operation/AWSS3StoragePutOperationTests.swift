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
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: "",
                                             uploadSource: UploadSource.data(data: testData),
                                             contentType: nil,
                                             metadata: nil,
                                             options: nil)
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
        mockAuthService.getIdentityIdError = StorageError.identity("", "")
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: UploadSource.data(data: testData),
                                             contentType: nil,
                                             metadata: nil,
                                             options: nil)
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StoragePutOperation(request,
                                                 storageService: mockStorageService,
                                                 authService: mockAuthService) { (event) in
            switch event {
            case .failed(let error):
                guard case .identity = error else {
                    XCTFail("Should have failed with identity error")
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
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: UploadSource.file(file: url),
                                             contentType: nil,
                                             metadata: nil,
                                             options: nil)
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StoragePutOperation(request,
                                                 storageService: mockStorageService,
                                                 authService: mockAuthService) { (event) in
            switch event {
            case .failed(let error):
                guard case .missingFile = error else {
                    XCTFail("Should have failed with missing file error")
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
            StorageEvent.initiated(StorageOperationReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(())]

        let expectedUploadSource = UploadSource.data(data: testData)
        let metadata = ["mykey": "Value"]
        let expectedMetadata = ["x-amz-meta-mykey": "Value"]
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: expectedUploadSource,
                                             contentType: testContentType,
                                             metadata: metadata,
                                             options: nil)
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
            StorageEvent.initiated(StorageOperationReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageError.service("", ""))]

        let expectedUploadSource = UploadSource.data(data: testData)
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: expectedUploadSource,
                                             contentType: nil,
                                             metadata: nil,
                                             options: nil)
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
            StorageEvent.initiated(StorageOperationReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(())]

        var testLargeDataString = "testLargeDataString"
        for _ in 1...20 {
            testLargeDataString += testLargeDataString
        }
        let testLargeData = testLargeDataString.data(using: .utf8)!
        XCTAssertTrue(testLargeData.count > PluginConstants.multiPartUploadSizeThreshold,
                      "Could not create data object greater than MultiPartUploadSizeThreshold")
        let expectedUploadSource = UploadSource.data(data: testLargeData)
        let metadata = ["mykey": "Value"]
        let expectedMetadata = ["x-amz-meta-mykey": "Value"]
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: expectedUploadSource,
                                             contentType: testContentType,
                                             metadata: metadata,
                                             options: nil)
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
