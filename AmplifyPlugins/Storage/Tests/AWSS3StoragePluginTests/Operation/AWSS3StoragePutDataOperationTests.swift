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

class AWSS3StorageUploadDataOperationTests: AWSS3StorageOperationTestBase {

    func testUploadDataOperationValidationError() async {
        let options = StorageUploadDataRequest.Options(accessLevel: .protected)
        let request = StorageUploadDataRequest(key: "", data: testData, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(request,
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

        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    func testUploadDataOperationGetIdentityIdError() async {
        mockAuthService.getIdentityIdError = AuthError.service("", "", "")

        let options = StorageUploadDataRequest.Options(accessLevel: .protected)
        let request = StorageUploadDataRequest(key: testKey, data: testData, options: options)

        let failedInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(request,
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

        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    func testUploadDataOperationUploadSuccess() async {
        mockAuthService.identityId = testIdentityId
        let task = StorageTransferTask(transferType: .upload(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completedVoid]

        let expectedUploadSource = UploadSource.data(testData)
        let metadata = ["mykey": "Value"]

        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType)
        let request = StorageUploadDataRequest(key: testKey, data: testData, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(
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

        await fulfillment(of: [completeInvoked, inProcessInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.uploadCalled, 1)
        mockStorageService.verifyUpload(serviceKey: expectedServiceKey,
                                        key: testKey,
                                        uploadSource: expectedUploadSource,
                                        contentType: testContentType,
                                        metadata: metadata)
    }

    func testUploadDataOperationUploadFail() async {
        mockAuthService.identityId = testIdentityId
        let task = StorageTransferTask(transferType: .upload(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.failed(StorageError.service("", ""))]

        let expectedUploadSource = UploadSource.data(testData)

        let options = StorageUploadDataRequest.Options(accessLevel: .protected)
        let request = StorageUploadDataRequest(key: testKey, data: testData, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let failInvoked = expectation(description: "failed was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(
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

        await fulfillment(of: [failInvoked, inProcessInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.uploadCalled, 1)
        mockStorageService.verifyUpload(serviceKey: expectedServiceKey,
                                        key: testKey,
                                        uploadSource: expectedUploadSource,
                                        contentType: nil,
                                        metadata: nil)
    }

    func testUploadDataOperationMultiPartUploadSuccess() async {
        mockAuthService.identityId = testIdentityId
        let task = StorageTransferTask(transferType: .multiPartUpload(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceMultiPartUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completedVoid]

        var testLargeDataString = "testLargeDataString"
        for _ in 1 ... 20 {
            testLargeDataString += testLargeDataString
        }
        let testLargeData = Data(testLargeDataString.utf8)
        XCTAssertTrue(testLargeData.count > StorageUploadDataRequest.Options.multiPartUploadSizeThreshold,
                      "Could not create data object greater than MultiPartUploadSizeThreshold")
        let expectedUploadSource = UploadSource.data(testLargeData)
        let metadata = ["mykey": "Value"]

        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType)
        let request = StorageUploadDataRequest(key: testKey, data: testLargeData, options: options)

        let expectedServiceKey = StorageAccessLevel.protected.rawValue + "/" + testIdentityId + "/" + testKey
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(
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

        await fulfillment(of: [completeInvoked, inProcessInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.multiPartUploadCalled, 1)
        mockStorageService.verifyMultiPartUpload(serviceKey: expectedServiceKey,
                                                 key: testKey,
                                                 uploadSource: expectedUploadSource,
                                                 contentType: testContentType,
                                                 metadata: metadata)
    }

    /// Given: Storage Upload Data Operation
    /// When: The operation is executed with a request that has an invalid StringStoragePath
    /// Then: The operation will fail with a validation error
    func testUploadDataOperationStringStoragePathValidationError() async {
        let path = StringStoragePath(resolve: { _ in return "/my/path" })
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let options = StorageUploadDataRequest.Options(accessLevel: .protected)
        let request = StorageUploadDataRequest(path: path, data: testData, options: options)
        let operation = AWSS3StorageUploadDataOperation(request,
                                                        storageConfiguration: testStorageConfiguration,
                                                        storageService: mockStorageService,
                                                        authService: mockAuthService,
                                                        progressListener: nil
        ) { result in
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
        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    /// Given: Storage Upload Data Operation
    /// When: The operation is executed with a request that has an invalid StringStoragePath
    /// Then: The operation will fail with a validation error
    func testUploadDataOperationEmptyStoragePathValidationError() async {
        let path = StringStoragePath(resolve: { _ in return " " })
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let options = StorageUploadDataRequest.Options(accessLevel: .protected)
        let request = StorageUploadDataRequest(path: path, data: testData, options: options)
        let operation = AWSS3StorageUploadDataOperation(request,
                                                        storageConfiguration: testStorageConfiguration,
                                                        storageService: mockStorageService,
                                                        authService: mockAuthService,
                                                        progressListener: nil
        ) { result in
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
        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    /// Given: Storage Upload Data Operation
    /// When: The operation is executed with a request that has an invalid IdentityIDStoragePath
    /// Then: The operation will fail with a validation error
    func testUploadDataOperationIdentityIDStoragePathValidationError() async {
        let path = IdentityIDStoragePath(resolve: { _ in return "/my/path" })
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let options = StorageUploadDataRequest.Options(accessLevel: .protected)
        let request = StorageUploadDataRequest(path: path, data: testData, options: options)
        let operation = AWSS3StorageUploadDataOperation(request,
                                                        storageConfiguration: testStorageConfiguration,
                                                        storageService: mockStorageService,
                                                        authService: mockAuthService,
                                                        progressListener: nil
        ) { result in
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
        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    /// Given: Storage Upload Data Operation
    /// When: The operation is executed with a request that has an a custom implementation of StoragePath
    /// Then: The operation will fail with a validation error
    func testUploadDataOperationCustomStoragePathValidationError() async {
        let path = InvalidCustomStoragePath(resolve: { _ in return "my/path" })
        let failedInvoked = expectation(description: "failed was invoked on operation")
        let options = StorageUploadDataRequest.Options(accessLevel: .protected)
        let request = StorageUploadDataRequest(path: path, data: testData, options: options)
        let operation = AWSS3StorageUploadDataOperation(request,
                                                        storageConfiguration: testStorageConfiguration,
                                                        storageService: mockStorageService,
                                                        authService: mockAuthService,
                                                        progressListener: nil
        ) { result in
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
        await fulfillment(of: [failedInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
    }

    /// Given: Storage Upload Data Operation
    /// When: The operation is executed with a request that has an valid StringStoragePath
    /// Then: The operation will succeed
    func testUploadDataOperationWithStringStoragePathSucceeds() async throws {
        let path = StringStoragePath(resolve: { _ in return "public/\(self.testKey)" })
        let task = StorageTransferTask(transferType: .upload(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completedVoid]

        let expectedUploadSource = UploadSource.data(testData)
        let metadata = ["mykey": "Value"]

        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType)
        let request = StorageUploadDataRequest(path: path, data: testData, options: options)

        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(
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

        await fulfillment(of: [completeInvoked, inProcessInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.uploadCalled, 1)
        mockStorageService.verifyUpload(serviceKey: "public/\(self.testKey)",
                                        key: testKey,
                                        uploadSource: expectedUploadSource,
                                        contentType: testContentType,
                                        metadata: metadata)
    }

    /// Given: Storage UploadData Operation
    /// When: The operation is executed with a request that has an valid IdentityIDStoragePath
    /// Then: The operation will succeed
    func testUploadDataOperationWithIdentityIDStoragePathSucceeds() async throws {
        mockAuthService.identityId = testIdentityId
        let path = IdentityIDStoragePath(resolve: { id in return "public/\(id)/\(self.testKey)" })
        let task = StorageTransferTask(transferType: .upload(onEvent: { _ in }), bucket: "bucket", key: "key")
        mockStorageService.storageServiceUploadEvents = [
            StorageEvent.initiated(StorageTaskReference(task)),
            StorageEvent.inProcess(Progress()),
            StorageEvent.completedVoid]

        let expectedUploadSource = UploadSource.data(testData)
        let metadata = ["mykey": "Value"]

        let options = StorageUploadDataRequest.Options(accessLevel: .protected,
                                                metadata: metadata,
                                                contentType: testContentType)
        let request = StorageUploadDataRequest(path: path, data: testData, options: options)
        let inProcessInvoked = expectation(description: "inProgress was invoked on operation")
        let completeInvoked = expectation(description: "complete was invoked on operation")
        let operation = AWSS3StorageUploadDataOperation(
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

        await fulfillment(of: [completeInvoked, inProcessInvoked], timeout: 1)
        XCTAssertTrue(operation.isFinished)
        XCTAssertEqual(mockStorageService.uploadCalled, 1)
        mockStorageService.verifyUpload(serviceKey: "public/\(testIdentityId)/\(testKey)",
                                        key: testKey,
                                        uploadSource: expectedUploadSource,
                                        contentType: testContentType,
                                        metadata: metadata)
    }

    // TODO: test pause, resume, canel, etc.
}
