//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
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
        let operation = Amplify.Storage.downloadData(key: key, options: options) { event in
            switch event {
            case .completed:
                XCTFail("Should not have completed successfully")
            case .failed(let error):
                guard case let .keyNotFound(key, errorDescription, _, _) = error else {
                    XCTFail("Should have been validation error")
                    return
                }

                XCTAssertEqual(key, expectedKey)
                failInvoked.fulfill()
            default:
                break
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
        let operation = Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil) { event in
            switch event {
            case .completed:
                XCTFail("Completed event is received")
            case .failed(let error):
                guard case let .localFileNotFound(error) = error else {
                    XCTFail("Should have been service error with missing File description")
                    return
                }
                //XCTAssertEqual(error.0, StorageErrorConstants.missingFile.errorDescription)
                failedInvoked.fulfill()
            default:
                break
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
