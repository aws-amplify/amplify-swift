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

class AWSS3StorageRemoveOperationTests: AWSS3StorageOperationTestBase {

    func testRemoveOperationValidationError() {
        let request = AWSS3StorageRemoveRequest(accessLevel: .public,
                                                key: "",
                                                pluginOptions: nil)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageRemoveOperation(request,
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

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
    }

    func testRemoveOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = StorageError.identity("", "")
        let request = AWSS3StorageRemoveRequest(accessLevel: .public,
                                                key: testKey,
                                                pluginOptions: nil)
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageRemoveOperation(request,
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

    func testRemoveOperationDeleteSuccess() {
        mockStorageService.storageServiceDeleteEvents = [StorageEvent.completed(())]
        let request = AWSS3StorageRemoveRequest(accessLevel: .public,
                                                key: testKey,
                                                pluginOptions: nil)
        let expectedServiceKey = StorageAccessLevel.public.rawValue + "/" + testKey
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageRemoveOperation(request,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        }

        operation.start()

        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDelete(serviceKey: expectedServiceKey)
    }

    func testRemoveOperationDeleteFail() {
        mockStorageService.storageServiceDeleteEvents = [StorageEvent.failed(StorageError.service("", ""))]
        let request = AWSS3StorageRemoveRequest(accessLevel: .public,
                                                key: testKey,
                                                pluginOptions: nil)
        let expectedServiceKey = StorageAccessLevel.public.rawValue + "/" + testKey
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageRemoveOperation(request,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { (event) in
            switch event {
            case .failed:
                failedInvoked.fulfill()
            default:
                XCTFail("Should have received failed event")
            }
        }

        operation.start()

        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDelete(serviceKey: expectedServiceKey)
    }

    func testRemoveOperationDeleteForPrivateAccessLevel() {
        mockAuthService.identityId = testIdentityId
        mockStorageService.storageServiceDeleteEvents = [StorageEvent.completed(())]
        let request = AWSS3StorageRemoveRequest(accessLevel: .private,
                                                key: testKey,
                                                pluginOptions: nil)
        let expectedServiceKey = StorageAccessLevel.private.rawValue + "/" + testIdentityId + "/" + testKey
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageRemoveOperation(request,
                                                    storageService: mockStorageService,
                                                    authService: mockAuthService) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        }

        operation.start()

        waitForExpectations(timeout: 1)
        XCTAssertTrue(operation.isFinished)
        mockStorageService.verifyDelete(serviceKey: expectedServiceKey)
    }
}
