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

class AWSS3StorageGetOperationTests: AWSS3StorageOperationTestBase {

    func testGetOperationValidationError() {
        let request = AWSS3StorageGetRequest(accessLevel: .public,
                                             targetIdentityId: nil,
                                             key: "",
                                             storageGetDestination: .data,
                                             options: nil)
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageGetOperation(request,
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

    func testGetOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.identity("", "")
        let request = AWSS3StorageGetRequest(accessLevel: .public,
                                             targetIdentityId: nil,
                                             key: testKey,
                                             storageGetDestination: .data,
                                             options: nil)
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageGetOperation(request,
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

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
    }

    func testGetOperationDownloadData() {
        mockStorageService.storageDownloadEvents = [
            StorageEvent.initiated(StorageOperationReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(StorageGetResult(data: Data()))]
        let request = AWSS3StorageGetRequest(accessLevel: .public,
                                             targetIdentityId: nil,
                                             key: testKey,
                                             storageGetDestination: .data,
                                             options: nil)
        let expectedServiceKey = StorageAccessLevel.public.rawValue + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageGetOperation(request,
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

    func testGetOperationDownloadDataFailed() {
        mockStorageService.storageDownloadEvents = [
            StorageEvent.initiated(StorageOperationReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageGetError.service("", ""))]
        let request = AWSS3StorageGetRequest(accessLevel: .public,
                                             targetIdentityId: nil,
                                             key: testKey,
                                             storageGetDestination: .data,
                                             options: nil)
        let expectedServiceKey = StorageAccessLevel.public.rawValue + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let failInvoked = expectation(description: "fail was invoked on operation")
        let operation = AWSS3StorageGetOperation(request,
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
        mockStorageService.storageDownloadEvents = [
            StorageEvent.initiated(StorageOperationReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(StorageGetResult(data: Data()))]
        let request = AWSS3StorageGetRequest(accessLevel: .protected,
                                             targetIdentityId: testTargetIdentityId,
                                             key: testKey,
                                             storageGetDestination: .data,
                                             options: nil)
        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testTargetIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageGetOperation(request,
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

    func testGetOperationDownloadLocal() {
        mockStorageService.storageDownloadEvents = [
            StorageEvent.initiated(StorageOperationReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(StorageGetResult(data: Data()))]
        let url = URL(fileURLWithPath: "path")
        let request = AWSS3StorageGetRequest(accessLevel: .public,
                                             targetIdentityId: nil,
                                             key: testKey,
                                             storageGetDestination: .file(local: url),
                                             options: nil)
        let expectedServiceKey = StorageAccessLevel.public.rawValue + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageGetOperation(request,
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

        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: url)
    }

    func testGetOperationDownloadLocalFromTargetIdentityId() {
        mockStorageService.storageDownloadEvents = [
            StorageEvent.initiated(StorageOperationReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(StorageGetResult(data: Data()))]
        let url = URL(fileURLWithPath: "path")
        let request = AWSS3StorageGetRequest(accessLevel: .protected,
                                             targetIdentityId: testTargetIdentityId,
                                             key: testKey,
                                             storageGetDestination: .file(local: url),
                                             options: nil)
        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testTargetIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageGetOperation(request,
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
        mockStorageService.verifyDownload(serviceKey: expectedServiceKey, fileURL: url)
    }

    func testGetOperationGetPresignedURL() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageGetPreSignedURLEvents = [
            StorageEvent.initiated(StorageOperationReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(StorageGetResult(remote: URL(fileURLWithPath: "path")))]
        let expectedExpires = 100
        let request = AWSS3StorageGetRequest(accessLevel: .protected,
                                             targetIdentityId: nil,
                                             key: testKey,
                                             storageGetDestination: .url(expires: expectedExpires),
                                             options: nil)
        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageGetOperation(request,
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
        XCTAssertEqual(mockStorageService.getPreSignedURLCalled, 1)
        waitForExpectations(timeout: 1)
        mockStorageService.verifyGetPreSignedURL(serviceKey: expectedServiceKey, expires: expectedExpires)
    }

    func testGetOperationGetPresignedURLFromTargetIdentityId() {
        mockStorageService.storageGetPreSignedURLEvents = [
            StorageEvent.initiated(StorageOperationReference(AWSS3TransferUtilityTask())),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completed(StorageGetResult(remote: URL(fileURLWithPath: "path")))]
        let request = AWSS3StorageGetRequest(accessLevel: .protected,
                                             targetIdentityId: testTargetIdentityId,
                                             key: testKey,
                                             storageGetDestination: .url(expires: nil),
                                             options: nil)
        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testTargetIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageGetOperation(request,
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
        XCTAssertEqual(mockStorageService.getPreSignedURLCalled, 1)
        waitForExpectations(timeout: 1)
        mockStorageService.verifyGetPreSignedURL(serviceKey: expectedServiceKey, expires: nil)
    }

    // TODO: missing unit tets for pause resume and cancel. do we create a mock of the StorageOperationReference?
}
