//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify

import AWSS3StoragePlugin
import ClientRuntime
import CryptoKit
import XCTest

class AWSS3StoragePluginDownloadIntegrationTests: AWSS3StoragePluginTestBase {
    /// Given: An object in storage
    /// When: Call the downloadData API
    /// Then: The operation completes successfully with the data retrieved
    func testDownloadDataToMemory() async throws {
        let key = UUID().uuidString
        try await uploadData(key: key, data: Data(key.utf8))
        _ = try await Amplify.Storage.downloadData(path: .fromString("public/\(key)"), options: .init()).value
        _ = try await Amplify.Storage.remove(path: .fromString("public/\(key)"))
    }
    /// Given: An object in storage
    /// When: Call the downloadFile API
    /// Then: The operation completes successfully the local file containing the data from the object
    func testDownloadFile() async throws {
        let key = UUID().uuidString
        let timestamp = String(Date().timeIntervalSince1970)
        let timestampData = Data(timestamp.utf8)
        try await uploadData(key: key, data: timestampData)
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        removeIfExists(fileURL)

        _ = try await Amplify.Storage.downloadFile(path: .fromString("public/\(key)"), local: fileURL, options: .init()).value

        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        XCTAssertTrue(fileExists)
        do {
            let result = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual(result, timestamp)
        } catch {
            XCTFail("Failed to read file that has been downloaded to")
        }
        removeIfExists(fileURL)
        _ = try await Amplify.Storage.remove(key: key)
    }

    func removeIfExists(_ fileURL: URL) {
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        if fileExists {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                XCTFail("Failed to delete file at \(fileURL)")
            }
        }
    }
}
