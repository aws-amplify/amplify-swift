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
        let failInvoked = expectation(description: "Failed is invoked")
        do {
            _ = try await Amplify.Storage.downloadData(key: key, options: .init()).value
            XCTFail("Expected error from Download operation")
        } catch StorageError.keyNotFound(let key, _, _, _) {
            XCTAssertEqual(key, expectedKey)
            failInvoked.fulfill()
        } catch {
            XCTFail("Expected StorageError.keyNotFound error, got \(error)")
        }

        await fulfillment(of: [failInvoked], timeout: 600)
    }

    /// Given: Object does not exist in storage
    /// When: Call the downloadFile API with path to local file
    /// Then: Download fails and local file should not exist
    func testDownloadToFileNonexistentKey() async {
        let key = UUID().uuidString
        let expectedKey = "public/" + key
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        let failInvoked = expectation(description: "Failed is invoked")

        do {
            _ = try await Amplify.Storage.downloadFile(key: key, local: fileURL, options: nil).value
        } catch StorageError.keyNotFound(let key, _, _, _) {
            XCTAssertEqual(key, expectedKey)
            failInvoked.fulfill()
        } catch {
            XCTFail("Expected StorageError.keyNotFound error, got \(error)")
        }

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: fileURL.path),
            "local file should not exist"
        )

        await fulfillment(of: [failInvoked], timeout: 600)

    }

    /// Given: A path to file that does not exist
    /// When: Upload the file
    /// Then: The operation fails with StorageError.missingLocalFile
    func testUploadFileFromMissingFile() async {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        let failInvoked = expectation(description: "Failed is invoked")

        do {
            _ = try await Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil).value
        } catch StorageError.localFileNotFound(let description, _, _) {
            XCTAssertEqual(
                description,
                StorageErrorConstants.localFileNotFound.errorDescription
            )
            failInvoked.fulfill()
        } catch {
            XCTFail("Expected localFileNotFound error, got \(error)")
        }

        await fulfillment(of: [failInvoked], timeout: 600)

    }

    /// Given: An unreadable file
    /// When: An attempt to upload it is made
    /// Then: A StorageError.accessDenied error is propagated to the caller
    func testUploadUnreadableFile() async throws {
        let key = UUID().uuidString
        let path = NSTemporaryDirectory() + key + ".tmp"
        FileManager.default.createFile(atPath: path,
                                       contents: Data(key.utf8),
                                       attributes: [FileAttributeKey.posixPermissions: 000])
        defer {
            try? FileManager.default.removeItem(atPath: path)
        }

        let url = URL(fileURLWithPath: path)
        do {
            _ = try await Amplify.Storage.uploadFile(key: key, local: url, options: nil).value
        } catch StorageError.accessDenied(let description, let recommendation, let underlyingError) {
            XCTAssertEqual(description, "Access to local file denied: \(path)")
            XCTAssertEqual(recommendation, "Please ensure that \(url) is readable")
            XCTAssertNil(underlyingError)
        }
    }

    // TODO: possibly after understanding content-type
//    func testPutWithInvalidContentType() {
//
//    }
}
