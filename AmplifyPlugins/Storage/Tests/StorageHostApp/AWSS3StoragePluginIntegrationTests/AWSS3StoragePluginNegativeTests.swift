//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin
import AmplifyAsyncTesting

class AWSS3StoragePluginNegativeTests: AWSS3StoragePluginTestBase {

    /// Given: Object with key `key` does not exist in storage
    /// When: Call the get API
    /// Then: The operation fails with StorageError.keyNotFound
    func testGetNonexistentKey() async {
        let key = UUID().uuidString
        let expectedKey = "public/" + key
        let failInvoked = asyncExpectation(description: "Failed is invoked")
        Task {
            do {
                let options = StorageDownloadDataRequest.Options()
                _ = try await Amplify.Storage.downloadData(key: key, options: options).value
                XCTFail("Should not have completed successfully")
                await failInvoked.fulfill()
            } catch {
                await failInvoked.fulfill()
                guard let storageError = error as? StorageError,
                      case let .keyNotFound(key, _, _, _) = storageError else {
                    XCTFail("Expected keyNotFound error, got \(error)")
                    return
                }
                XCTAssertEqual(key, expectedKey)
            }
        }
        await waitForExpectations([failInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: Object does not exist in storage
    /// When: Call the downloadFile API with path to local file
    /// Then: Download fails and local file should not exist
    func testDownloadToFileNonexistentKey() async {
        let key = UUID().uuidString
        let expectedKey = "public/" + key
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        let failInvoked = asyncExpectation(description: "Failed is invoked")
        Task {
            do {
                _ = try await Amplify.Storage.downloadFile(key: key, local: fileURL, options: nil).value
                XCTFail("Should not have completed successfully")
                await failInvoked.fulfill()
            } catch {
                await failInvoked.fulfill()
                guard let storageError = error as? StorageError,
                      case let .keyNotFound(key, _, _, _) = storageError else {
                    XCTFail("Expected keyNotFound error, got \(error)")
                    return
                }

                if FileManager.default.fileExists(atPath: fileURL.path) {
                    XCTFail("local file should not exist")
                }
                XCTAssertEqual(key, expectedKey)
            }
        }
        await waitForExpectations([failInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A path to file that does not exist
    /// When: Upload the file
    /// Then: The operation fails with StorageError.missingLocalFile
    func testUploadFileFromMissingFile() async {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        let failedInvoked = asyncExpectation(description: "Failed is invoked")
        Task {
            do {
                _ = try await Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil).value
                XCTFail("Completed event is received")
                await failedInvoked.fulfill()
            } catch {
                await failedInvoked.fulfill()
                guard let storageError = error as? StorageError,
                      case let .localFileNotFound(description, _, _) = storageError else {
                    XCTFail("Expected localFileNotFound error, got \(error)")
                    return
                }
                XCTAssertEqual(description, StorageErrorConstants.localFileNotFound.errorDescription)
            }
        }
        await waitForExpectations([failedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    // TODO: possibly after understanding content-type
//    func testPutWithInvalidContentType() {
//
//    }
}
