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

class AWSS3StorageGetURLOperationTests: AWSS3StorageOperationTestBase {

    func testGetURLOperationValidationError() {
        let options = StorageGetURLRequest.Options(expires: 0)
        let request = StorageGetURLRequest(key: "", options: options)
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageGetURLOperation(request,
                                                    storageConfiguration: testStorageConfiguration,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { result in
            switch result {
            case .failure(let error):
                guard case .validation = error else {
                    XCTFail("Should have failed with validation error, not \(error)")
                    return
                }
                failedInvoked.fulfill()
            case .success(let url):
                XCTFail("Should have received failed event, got \(url)")
            }
        }

        operation.start()
        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    func testGetURLOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.service("", "", "")

        let options = StorageGetURLRequest.Options(expires: testExpires)
        let request = StorageGetURLRequest(key: testKey, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageGetURLOperation(request,
                                                    storageConfiguration: testStorageConfiguration,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { result in
            switch result {
            case .failure(let error):
                guard case .authError = error else {
                    XCTFail("Should have failed with authError, not \(error)")
                    return
                }
                failedInvoked.fulfill()
            case .success(let url):
                XCTFail("Should have received failed event, got \(url)")
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
                                                    storageConfiguration: testStorageConfiguration,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error on operation: \(error)")
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
                                                    storageConfiguration: testStorageConfiguration,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { result in
            switch result {
            case .failure:
                failedInvoked.fulfill()
            case .success(let url):
                XCTFail("Should have received failed event, got \(url)")
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
                                                    storageConfiguration: testStorageConfiguration,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error on operation: \(error)")
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
