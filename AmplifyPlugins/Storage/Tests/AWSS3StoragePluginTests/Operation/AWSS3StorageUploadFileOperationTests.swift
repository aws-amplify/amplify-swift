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

class AWSS3StorageUploadFileOperationTests: AWSS3StorageOperationTestBase {

    func testUploadFileOperationValidationError() {
        let options = StorageUploadFileRequest.Options(accessLevel: .protected)
        let request = StorageUploadFileRequest(key: "", local: testURL, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageUploadFileOperation(request,
                                                        storageConfiguration: testStorageConfiguration,
                                                        storageService: mockStorageService,
                                                        authService: mockAuthService,
                                                        progressListener: nil) { result in
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

    func testUploadFileOperationGetIdentityIdError() {
        mockAuthService.getIdentityIdError = AuthError.service("", "", "")
        let filePath = NSTemporaryDirectory() + UUID().uuidString + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: testData, attributes: nil)
        let options = StorageUploadFileRequest.Options(accessLevel: .protected)
        let request = StorageUploadFileRequest(key: testKey, local: fileURL, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageUploadFileOperation(request,
                                                        storageConfiguration: testStorageConfiguration,
                                                        storageService: mockStorageService,
                                                        authService: mockAuthService,
                                                        progressListener: nil) { result in
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

    func testvOperationGetSizeForMissingFileError() {
        let url = URL(fileURLWithPath: "missingFile")
        let options = StorageUploadFileRequest.Options(accessLevel: .protected)
        let request = StorageUploadFileRequest(key: testKey, local: url, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageUploadFileOperation(request,
                                                        storageConfiguration: testStorageConfiguration,
                                                        storageService: mockStorageService,
                                                        authService: mockAuthService,
                                                        progressListener: nil) { event in
            switch event {
            case .failure(let error):
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
        waitForOperationToFinish(operation)
    }

    func testUploadFileOperationUploadSuccess() {
        mockAuthService.identityId = testIdentityId
        let task = StorageTransferTask(transferType: .upload(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completedVoid]

        let filePath = NSTemporaryDirectory() + UUID().uuidString + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: testData, attributes: nil)
        let expectedUploadSource = UploadSource.local(fileURL)
        let metadata = ["mykey": "Value"]
        let expectedMetadata = ["x-amz-meta-mykey": "Value"]

        let options = StorageUploadFileRequest.Options(accessLevel: .protected,
                                                       metadata: metadata,
                                                       contentType: testContentType)
        let request = StorageUploadFileRequest(key: testKey, local: fileURL, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageUploadFileOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        })

        operation.start()

        waitForExpectations(timeout: 1)
        waitForOperationToFinish(operation)
        XCTAssertEqual(mockStorageService.uploadCalled, 1)
        mockStorageService.verifyUpload(serviceKey: expectedServiceKey,
                                        key: testKey,
                                        uploadSource: expectedUploadSource,
                                        contentType: testContentType,
                                        metadata: expectedMetadata)
    }

    func testUploadFileOperationUploadFail() {
        mockAuthService.identityId = testIdentityId
        let task = StorageTransferTask(transferType: .upload(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageError.service("", ""))]

        let filePath = NSTemporaryDirectory() + UUID().uuidString + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: testData, attributes: nil)
        let expectedUploadSource = UploadSource.local(fileURL)

        let options = StorageUploadFileRequest.Options(accessLevel: .protected)
        let request = StorageUploadFileRequest(key: testKey, local: fileURL, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let failInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageUploadFileOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .failure:
                failInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        })

        operation.start()

        waitForExpectations(timeout: 1)
        waitForOperationToFinish(operation)
        XCTAssertEqual(mockStorageService.uploadCalled, 1)
        mockStorageService.verifyUpload(serviceKey: expectedServiceKey,
                                        key: testKey,
                                        uploadSource: expectedUploadSource,
                                        contentType: nil,
                                        metadata: nil)
    }

    func testUploadFileOperationMultiPartUploadSuccess() {
        mockAuthService.identityId = testIdentityId
        let task = StorageTransferTask(transferType: .multiPartUpload(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceMultiPartUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completedVoid]

        let largeDataObject = Data(repeating: 0xff, count: 1_024 * 1_024 * 6) // 6MB
        let filePath = NSTemporaryDirectory() + UUID().uuidString + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: largeDataObject, attributes: nil)
        XCTAssertTrue(largeDataObject.count > StorageUploadDataRequest.Options.multiPartUploadSizeThreshold,
                      "Could not create data object greater than MultiPartUploadSizeThreshold")
        let expectedUploadSource = UploadSource.local(testURL)
        let metadata = ["mykey": "Value"]
        let expectedMetadata = ["x-amz-meta-mykey": "Value"]

        let options = StorageUploadFileRequest.Options(accessLevel: .protected,
                                                       metadata: metadata,
                                                       contentType: testContentType)
        let request = StorageUploadFileRequest(key: testKey, local: fileURL, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageUploadFileOperation(
            request,
            storageConfiguration: testStorageConfiguration,
            storageService: mockStorageService,
            authService: mockAuthService,
            progressListener: { _ in
                inProcessInvoked.fulfill()
        }, resultListener: { result in
            switch result {
            case .success:
                completeInvoked.fulfill()
            default:
                XCTFail("Should have received completed event")
            }
        })

        operation.start()

        waitForExpectations(timeout: 1)
        waitForOperationToFinish(operation)
        XCTAssertEqual(mockStorageService.multiPartUploadCalled, 1)
        mockStorageService.verifyMultiPartUpload(serviceKey: expectedServiceKey,
                                                 key: testKey,
                                                 uploadSource: expectedUploadSource,
                                                 contentType: testContentType,
                                                 metadata: expectedMetadata)
    }

    // TODO: test pause, resume, canel, etc.
}
