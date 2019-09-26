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

class AWSS3StorageGetDataOperationTests: AWSS3StorageOperationTestBase {

    func testGetDataOperationValidationError() {
        let request = StorageGetDataRequest(key: "", options: StorageGetDataRequest.Options())
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageGetDataOperation(request,
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

    func testGetDataOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.identity("", "", "")
        let request = StorageGetDataRequest(key: testKey, options: StorageGetDataRequest.Options())
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageGetDataOperation(request,
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

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
    }

    func testGetDataOperationDownloadData() {
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(Data())]
        let request = StorageGetDataRequest(key: testKey, options: StorageGetDataRequest.Options())
        let expectedServiceKey = StorageAccessLevel.public.rawValue + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageGetDataOperation(request,
                                                 storageService: mockStorageService,
                                                 authService: mockAuthService) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .inProcess:
                inProcessInvoked.fulfill()
            default:
                XCTFail("Unexpected event invoked on operation")
            }
        }

        operation.start()

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: nil)
    }

    func testGetDataOperationDownloadDataFailed() {
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageError.service("", ""))]
        let request = StorageGetDataRequest(key: testKey, options: StorageGetDataRequest.Options())
        let expectedServiceKey = StorageAccessLevel.public.rawValue + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let failInvoked = expectation(description: "fail was invoked on operation")
        let operation = AWSS3StorageGetDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { (event) in
            switch event {
            case .failed:
                failInvoked.fulfill()
            case .inProcess:
                inProcessInvoked.fulfill()
            default:
                XCTFail("Unexpected event invoked on operation")
            }
        }

        operation.start()

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: nil)
    }

    func testGetOperationDownloadDataFromTargetIdentityId() {
        mockStorageService.storageServiceDownloadEvents = [
            StorageEvent.initiated(StorageTaskReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(Data())]
        let options = StorageGetDataRequest.Options(accessLevel: .protected,
                                                    targetIdentityId: testTargetIdentityId)
        let request = StorageGetDataRequest(key: testKey, options: options)
        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testTargetIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageGetDataOperation(request,
                                                     storageService: mockStorageService,
                                                     authService: mockAuthService) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .inProcess:
                inProcessInvoked.fulfill()
            default:
                XCTFail("Unexpected event invoked on operation")
            }
        }

        operation.start()

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: nil)
    }

    // TODO: missing unit tets for pause resume and cancel. do we create a mock of the StorageTaskReference?
}
