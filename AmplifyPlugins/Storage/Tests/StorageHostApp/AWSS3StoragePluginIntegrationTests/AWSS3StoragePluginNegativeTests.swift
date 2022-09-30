//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginNegativeTests: AWSS3StoragePluginTestBase {

    /// Given: Object with key `key` does not exist in storage
    /// When: Call the get API
    /// Then: The operation fails with StorageError.keyNotFound
    func testGetNonexistentKey() async {
        let key = UUID().uuidString
        let expectedKey = "public/" + key
        let failInvoked = asyncExpectation(description: "Failed is invoked")
        let getError = await waitError(with: failInvoked) {
            return try await Amplify.Storage.downloadData(key: key, options: .init()).value
        }

        guard let getError = getError else {
            XCTFail("Expected error from Download operation")
            return
        }

        guard let storageError = getError as? StorageError,
              case let .keyNotFound(key, _, _, _) = storageError else {
            XCTFail("Expected keyNotFound error, got \(getError)")
            return
        }

        XCTAssertEqual(key, expectedKey)
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
        let getError = await waitError(with: failInvoked) {
            return try await Amplify.Storage.downloadFile(key: key, local: fileURL, options: nil).value
        }

        guard let getError = getError else {
            XCTFail("Expected error from Download operation")
            return
        }

        if FileManager.default.fileExists(atPath: fileURL.path) {
            XCTFail("local file should not exist")
        }

        guard let storageError = getError as? StorageError,
              case let .keyNotFound(key, _, _, _) = storageError else {
            XCTFail("Expected keyNotFound error, got \(getError)")
            return
        }
        XCTAssertEqual(key, expectedKey)
    }

    /// Given: A path to file that does not exist
    /// When: Upload the file
    /// Then: The operation fails with StorageError.missingLocalFile
    func testUploadFileFromMissingFile() async {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        let failedInvoked = asyncExpectation(description: "Failed is invoked")
        let uploadError = await waitError(with: failedInvoked) {
            return try await Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil).value
        }

        guard let uploadError = uploadError else {
            XCTFail("Expected error from Download operation")
            return
        }

        guard let storageError = uploadError as? StorageError,
              case let .localFileNotFound(description, _, _) = storageError else {
            XCTFail("Expected localFileNotFound error, got \(uploadError)")
            return
        }

        XCTAssertEqual(description, StorageErrorConstants.localFileNotFound.errorDescription)
    }

    // TODO: possibly after understanding content-type
//    func testPutWithInvalidContentType() {
//
//    }
}
