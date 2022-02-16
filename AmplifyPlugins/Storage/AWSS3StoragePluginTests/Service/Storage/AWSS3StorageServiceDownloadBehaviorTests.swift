//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/*
import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StorageServiceDownloadBehaviorTests: AWSS3StorageServiceTestBase {

    let testServiceKey = "TestServiceKey"
    let testFileURL = URL(fileURLWithPath: "path")

    func testStorageServiceDownloadData() {
        let completedInvoked = expectation(description: "Completed event was invoked")

        storageService.download(serviceKey: testServiceKey, fileURL: nil) { event in
            switch event {
            case .initiated:
                break
            case .inProcess:
                break
            case .completed:
                completedInvoked.fulfill()
            case .failed:
                XCTFail("Not yet implemented - status code needs to be in task.response")
            }
        }

        XCTAssertEqual(mockTransferUtility.downloadDataCalled, 1)
        waitForExpectations(timeout: 1.0)
    }

//    func testStorageServiceDownloadToFile() {
//        XCTFail("Not yet implemented")
//    }

//    func testStorageServiceExecuteGetRequest() {
//        // Arrange
//
//        failedInvoked.isInverted = true
//
//        // Act
//        storageService.execute(requestBuilder) { (storageEvent) in
//            switch storageEvent {
//            case .initiated:
//                self.initiatedInvoked.fulfill()
//            case .inProcess:
//                self.inProcessInvoked.fulfill()
//            case .completed:
//                self.completedInvoked.fulfill()
//            case .failed:
//                self.failedInvoked.fulfill()
//            }
//        }
//
//        // Assert
//        XCTAssertEqual(mockTransferUtility.downloadDataCalled, true)
//        waitForExpectations(timeout: 1.0)
//    }

//    func testStorageServiceDownloadDataWithErrorOnCompletion() {
//        mockTransferUtility.errorOnCompletion = NSError(domain: "domain", code: 0, userInfo: nil)
//        let failedInvoked = expectation(description: "Failed event was invoked")
//
//        storageService.download(serviceKey: testServiceKey, fileURL: testFileURL, onEvent: { (event) in
//            switch event {
//            case .initiated:
//                break
//            case .inProcess:
//                break
//            case .completed:
//                XCTFail("Should not receive completed event")
//            case .failed:
//                failedInvoked.fulfill()
//            }
//        })
//
//        // Assert
//        XCTAssertEqual(mockTransferUtility.downloadDataCalled, true)
//        waitForExpectations(timeout: 1.0)
//    }
}
*/
