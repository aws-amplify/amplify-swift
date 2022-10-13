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

class AWSS3StorageListOperationTests: AWSS3StorageOperationTestBase {

    func testListOperationValidationError() {
        let options = StorageListRequest.Options(path: "")
        let request = StorageListRequest(options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageListOperation(request,
                                                  storageConfiguration: testStorageConfiguration,
                                                  storageService: mockStorageService,
                                                  authService: mockAuthService) { result in
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
        waitForOperationToFinish(operation)
    }

    func testListOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.service("", "", "")

        let options = StorageListRequest.Options(path: testPath)
        let request = StorageListRequest(options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageListOperation(request,
                                                  storageConfiguration: testStorageConfiguration,
                                                  storageService: mockStorageService,
                                                  authService: mockAuthService) { result in
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
        waitForOperationToFinish(operation)
    }

    func testListOperationListObjects() {
        mockStorageService.storageServiceListEvents = [StorageEvent.completed(StorageListResult(items: []))]
        let options = StorageListRequest.Options(path: testPath)
        let request = StorageListRequest(options: options)

        let expectedPrefix = StorageAccessLevel.guest.serviceAccessPrefix + "/"
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageListOperation(request,
                                                  storageConfiguration: testStorageConfiguration,
                                                  storageService: mockStorageService,
                                                  authService: mockAuthService) { result in
                                                    switch result {
                                                    case .success:
                                                        completeInvoked.fulfill()
                                                    default:
                                                        XCTFail("Unexpected event invoked on operation")
                                                    }
        }

        operation.start()

        waitForExpectations(timeout: 1)
        waitForOperationToFinish(operation)
        mockStorageService.verifyList(prefix: expectedPrefix, path: testPath)
    }

    func testListOperationListObjectsFail() {
        mockStorageService.storageServiceListEvents = [StorageEvent.failed(StorageError.service("", ""))]
        let options = StorageListRequest.Options(path: testPath)
        let request = StorageListRequest(options: options)

        let expectedPrefix = StorageAccessLevel.guest.serviceAccessPrefix + "/"
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageListOperation(request,
                                                  storageConfiguration: testStorageConfiguration,
                                                  storageService: mockStorageService,
                                                  authService: mockAuthService) { result in
                                                    switch result {
                                                    case .failure:
                                                        failedInvoked.fulfill()
                                                    default:
                                                        XCTFail("Unexpected event invoked on operation")
                                                    }
        }

        operation.start()

        waitForExpectations(timeout: 1)
        waitForOperationToFinish(operation)
        mockStorageService.verifyList(prefix: expectedPrefix, path: testPath)
    }

    func testListOperationListObjectsForTargetIdentityId() {
        mockStorageService.storageServiceListEvents = [StorageEvent.completed(StorageListResult(items: []))]
        let options = StorageListRequest.Options(accessLevel: .protected,
                                                 targetIdentityId: testTargetIdentityId,
                                                 path: testPath)
        let request = StorageListRequest(options: options)

        let expectedPrefix = StorageAccessLevel.protected.rawValue + "/" + testTargetIdentityId + "/"
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageListOperation(request,
                                                  storageConfiguration: testStorageConfiguration,
                                                  storageService: mockStorageService,
                                                  authService: mockAuthService) { result in
                                                    switch result {
                                                    case .success:
                                                        completeInvoked.fulfill()
                                                    default:
                                                        XCTFail("Unexpected event invoked on operation")
                                                    }
        }

        operation.start()

        waitForExpectations(timeout: 1)
        waitForOperationToFinish(operation)
        mockStorageService.verifyList(prefix: expectedPrefix, path: testPath)
    }
}
