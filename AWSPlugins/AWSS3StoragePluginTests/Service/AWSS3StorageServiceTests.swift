//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StorageServiceTests: XCTestCase {
    var mockTransferUtility: MockAWSS3TransferUtility!
    var mockPreSignedURLBuilder: MockAWSS3PreSignedURLBuilder!
    var mockS3: MockS3!
    var mockMobileClient: MockAWSMobileClient!

    var storageService: AWSS3StorageService!

    var initiatedInvoked: XCTestExpectation!
    var inProcessInvoked: XCTestExpectation!
    var failedInvoked: XCTestExpectation!
    var completedInvoked: XCTestExpectation!

    override func setUp() {
        mockTransferUtility = MockAWSS3TransferUtility()
        mockPreSignedURLBuilder = MockAWSS3PreSignedURLBuilder()
        mockS3 = MockS3()
        mockMobileClient = MockAWSMobileClient()
        storageService = AWSS3StorageService(transferUtility: mockTransferUtility,
                                             preSignedURLBuilder: mockPreSignedURLBuilder,
                                             awsS3: mockS3,
                                             awsMobileClient: mockMobileClient)

        initiatedInvoked = expectation(description: "Iniaited event was invoked on storage service")
        inProcessInvoked = expectation(description: "InProcess event was invoked on storage service")
        completedInvoked = expectation(description: "Completed event was invoked on storage service")
        failedInvoked = expectation(description: "Failed event was invoked on storage service")
    }

    func testStorageServiceExecuteGetRequest() {
        // Arrange
        let requestBuilder = AWSS3StorageGetRequest.Builder(bucket: "bucket", key: "key")
        failedInvoked.isInverted = true

        // Act
        storageService.execute(requestBuilder) { (storageEvent) in
            switch storageEvent {
            case .initiated:
                self.initiatedInvoked.fulfill()
            case .inProcess:
                self.inProcessInvoked.fulfill()
            case .completed:
                self.completedInvoked.fulfill()
            case .failed:
                self.failedInvoked.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(mockTransferUtility.downloadDataCalled, true)
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceExecuteGetRequestWithErrorOnCompletion() {
        // Arrange
        mockTransferUtility.errorOnCompletion = NSError(domain: "domain", code: 0, userInfo: nil)
        let requestBuilder = AWSS3StorageGetRequest.Builder(bucket: "bucket", key: "key")
        initiatedInvoked.isInverted = false
        inProcessInvoked.isInverted = false
        completedInvoked.isInverted = true
        failedInvoked.isInverted = false

        // Act
        storageService.execute(requestBuilder) { (storageEvent) in
            switch storageEvent {
            case .initiated:
                self.initiatedInvoked.fulfill()
            case .inProcess:
                self.inProcessInvoked.fulfill()
            case .completed:
                self.completedInvoked.fulfill()
            case .failed:
                self.failedInvoked.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(mockTransferUtility.downloadDataCalled, true)
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceExecuteGetRequestWithErrorOnContinuation() {
        // Arrange
        mockTransferUtility.errorOnContinuation = NSError(domain: "domain", code: 0, userInfo: nil)
        let requestBuilder = AWSS3StorageGetRequest.Builder(bucket: "bucket", key: "key")
        initiatedInvoked.isInverted = true
        inProcessInvoked.isInverted = true
        completedInvoked.isInverted = true
        failedInvoked.isInverted = false

        // Act
        storageService.execute(requestBuilder) { (storageEvent) in
            switch storageEvent {
            case .initiated:
                self.initiatedInvoked.fulfill()
            case .inProcess:
                self.inProcessInvoked.fulfill()
            case .completed:
                self.completedInvoked.fulfill()
            case .failed:
                self.failedInvoked.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(mockTransferUtility.downloadDataCalled, true)
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceExecuteGetRequestWithFileURL() {
        // Arrange
        let url = URL(fileURLWithPath: "path")
        let requestBuilder = AWSS3StorageGetRequest.Builder(bucket: "bucket", key: "key").fileURL(url)
        initiatedInvoked.isInverted = false
        inProcessInvoked.isInverted = false
        completedInvoked.isInverted = false
        failedInvoked.isInverted = true

        // Act
        storageService.execute(requestBuilder) { (storageEvent) in
            switch storageEvent {
            case .initiated:
                self.initiatedInvoked.fulfill()
            case .inProcess:
                self.inProcessInvoked.fulfill()
            case .completed:
                self.completedInvoked.fulfill()
            case .failed:
                self.failedInvoked.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(mockTransferUtility.downloadToURLCalled, true)
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceExecuteGetUrlRequest() {
        initiatedInvoked.isInverted = true
        inProcessInvoked.isInverted = true
        completedInvoked.isInverted = true
        failedInvoked.isInverted = true
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceExecuteGetUrlRequestWithError() {
        initiatedInvoked.isInverted = true
        inProcessInvoked.isInverted = true
        completedInvoked.isInverted = true
        failedInvoked.isInverted = true
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceExecutePutRequest() {
        // we should build the content type into the mock;s verify. so that we expect the content type
        // and verify that it was called with the same content type that we expected.
        initiatedInvoked.isInverted = true
        inProcessInvoked.isInverted = true
        completedInvoked.isInverted = true
        failedInvoked.isInverted = true
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceExecuteWithErrorOnContinuation() {
        initiatedInvoked.isInverted = true
        inProcessInvoked.isInverted = true
        completedInvoked.isInverted = true
        failedInvoked.isInverted = true
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceExecuteWithErrorOnCompletion() {
        initiatedInvoked.isInverted = true
        inProcessInvoked.isInverted = true
        completedInvoked.isInverted = true
        failedInvoked.isInverted = true
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceExecuteListRequest() {
        // again we need to create a mock to verify that the request object created in AWSS3.listObjectsV2
        // is called with the prefix. we're testing that we've turned our request object into
        // the correct call to the dependency.
        initiatedInvoked.isInverted = true
        inProcessInvoked.isInverted = true
        completedInvoked.isInverted = true
        failedInvoked.isInverted = true
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceExecuteListRequestWithError() {
        initiatedInvoked.isInverted = true
        inProcessInvoked.isInverted = true
        completedInvoked.isInverted = true
        failedInvoked.isInverted = true
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceRemoveRequest() {
        initiatedInvoked.isInverted = true
        inProcessInvoked.isInverted = true
        completedInvoked.isInverted = true
        failedInvoked.isInverted = true
        waitForExpectations(timeout: 1.0)
    }

    func testStorageServiceRemoveRequestWithError() {
        initiatedInvoked.isInverted = true
        inProcessInvoked.isInverted = true
        completedInvoked.isInverted = true
        failedInvoked.isInverted = true
        waitForExpectations(timeout: 1.0)
    }
}
