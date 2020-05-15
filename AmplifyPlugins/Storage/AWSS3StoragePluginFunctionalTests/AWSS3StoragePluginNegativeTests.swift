//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import Amplify
@testable import AWSS3StoragePlugin
import AWSS3
@testable import AmplifyTestCommon

class AWSS3StoragePluginNegativeTests: AWSS3StoragePluginTestBase {

    /// Given: Object with key `key` does not exist in storage
    /// When: Call the get API
    /// Then: The operation fails with StorageError.keyNotFound
    func testGetNonexistentKey() {
        let key = UUID().uuidString
        let expectedKey = "public/" + key
        let failInvoked = expectation(description: "Failed is invoked")
        let options = StorageDownloadDataRequest.Options()
        let operation = Amplify.Storage.downloadData(
            key: key,
            options: options,
            progressListener: nil) { event in
                switch event {
                case .success:
                    XCTFail("Should not have completed successfully")
                case .failure(let error):
                    guard case let .keyNotFound(key, _, _, _) = error else {
                        XCTFail("Should have been validation error")
                        return
                    }

                    XCTAssertEqual(key, expectedKey)
                    failInvoked.fulfill()
                }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A path to file that does not exist
    /// When: Upload the file
    /// Then: The operation fails with StorageError.missingLocalFile
    func testUploadFileFromMissingFile() {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        let failedInvoked = expectation(description: "Failed is invoked")
        let operation = Amplify.Storage.uploadFile(
            key: key,
            local: fileURL,
            options: nil,
            progressListener: nil) { event in
                switch event {
                case .success:
                    XCTFail("Completed event is received")
                case .failure(let error):
                    guard case .localFileNotFound = error else {
                        XCTFail("Should have been service error with missing File description, not \(error)")
                        return
                    }
                    //XCTAssertEqual(error.0, StorageErrorConstants.missingFile.errorDescription)
                    failedInvoked.fulfill()
                }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    // TODO: possibly after understanding content-type
//    func testPutWithInvalidContentType() {
//
//    }
}
