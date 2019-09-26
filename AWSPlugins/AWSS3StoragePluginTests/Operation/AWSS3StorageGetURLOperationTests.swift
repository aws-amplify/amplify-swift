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

class AWSS3StorageGetURLOperationTests: AWSS3StorageOperationTestBase {

    func testGetURLOperationValidationError() {
        let options = StorageGetURLRequest.Options(expires: 0)
        let request = StorageGetURLRequest(key: "", options: options)
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageGetURLOperation(request,
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

    func testGetURLOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.identity("", "", "")
        
        let options = StorageGetURLRequest.Options(expires: testExpires)
        let request = StorageGetURLRequest(key: testKey, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageGetURLOperation(request,
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

    func testGetOperationGetPresignedURL() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceGetPreSignedURLEvents = [
            StorageEvent.completed(URL(fileURLWithPath: "path"))]
        let expectedExpires = 100

        let options = StorageGetURLRequest.Options(accessLevel: .protected, expires: expectedExpires)
        let request = StorageGetURLRequest(key: testKey, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageGetURLOperation(request,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
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

    func testGetOperationGetPresignedURLFailed() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceGetPreSignedURLEvents = [
            StorageEvent.failed(StorageError.service("", ""))]
        let expectedExpires = 100

        let options = StorageGetURLRequest.Options(accessLevel: .protected, expires: expectedExpires)
        let request = StorageGetURLRequest(key: testKey, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageGetURLOperation(request,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { (event) in
            switch event {
            case .failed:
                failedInvoked.fulfill()
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
        mockStorageService.storageServiceGetPreSignedURLEvents = [
            StorageEvent.completed(URL(fileURLWithPath: "path"))]

        let options = StorageGetURLRequest.Options(accessLevel: .protected, targetIdentityId: testTargetIdentityId)
        let request = StorageGetURLRequest(key: testKey, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testTargetIdentityId + "/" + testKey
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageGetURLOperation(request,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            default:
                XCTFail("Unexpected event invoked on operation")
            }
        }

        operation.start()

        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.getPreSignedURLCalled, 1)
        waitForExpectations(timeout: 1)
        mockStorageService.verifyGetPreSignedURL(serviceKey: expectedServiceKey,
                                                 expires: StorageGetURLRequest.Options.defaultExpireInSeconds)
    }
}
