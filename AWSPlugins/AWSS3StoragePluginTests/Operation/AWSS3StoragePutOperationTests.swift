//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StoragePutOperationTests: XCTestCase {
    var hubPlugin: MockHubCategoryPlugin!
    var mockStorageService: MockAWSS3StorageService!
    var mockAuthService: MockAWSAuthService!

    let testKey = "TestKey"
    let testData = Data()

    override func setUp() {
        let hubConfig = HubCategoryConfiguration(
            plugins: ["MockHubCategoryPlugin": true]
        )
        hubPlugin = MockHubCategoryPlugin()
        let mockAmplifyConfig = AmplifyConfiguration(hub: hubConfig)

        do {
            try Amplify.add(plugin: hubPlugin)
            try Amplify.configure(mockAmplifyConfig)
        } catch let error as AmplifyError {
            XCTFail("setUp failed with error: \(error); \(error.errorDescription); \(error.recoverySuggestion)")
        } catch {
            XCTFail("setup failed with unknown error")
        }

        let methodWasInvokedOnHubPlugin = expectation(
            description: "method was invoked on hub plugin")
        hubPlugin.listeners.append { message in
            if message == "dispatch(to:payload:)" {
                methodWasInvokedOnHubPlugin.fulfill()
            }
        }

        mockStorageService = MockAWSS3StorageService()
        mockAuthService = MockAWSAuthService()
    }

    override func tearDown() {
        Amplify.reset()
    }

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

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
    }

    func testPutOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.identity("", "")
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

        XCTAssertTrue(operation.isFinished)
        waitForExpectations(timeout: 1)
    }

    func testPutOperationUpload() {
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: UploadSource.data(data: testData),
                                             contentType: nil,
                                             metadata: nil,
                                             options: nil)
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StoragePutOperation(request,
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

        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.uploadCalled, true)
        waitForExpectations(timeout: 1)
    }

    // TODO: finalize on when to trigger multipart upload
    func testPutOperationMultiPartUpload() {
        let request = AWSS3StoragePutRequest(accessLevel: .protected,
                                             key: testKey,
                                             uploadSource: UploadSource.data(data: testData),
                                             contentType: nil,
                                             metadata: nil,
                                             options: nil)
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StoragePutOperation(request,
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

        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.multiPartUploadCalled, true)
        waitForExpectations(timeout: 1)
    }
}
