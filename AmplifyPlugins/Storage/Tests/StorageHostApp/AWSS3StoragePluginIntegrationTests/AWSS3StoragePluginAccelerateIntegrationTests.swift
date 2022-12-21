//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSS3StoragePlugin
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

class AWSS3StoragePluginAccelerateIntegrationTests: AWSS3StoragePluginTestBase {

    var useAccelerateEndpoint = false

    /// Given: A data object.
    /// When: It's uploaded with acceleration turned-off explicity.
    /// Then: The operation completes successfully.
    func testUploadDataWithAccelerateDisabledExplicitly() async throws {
        let key = UUID().uuidString
        let data = try XCTUnwrap(key.data(using: .utf8))
        let task = Amplify.Storage.uploadData(key: key,
                                              data: data,
                                              options: .init(pluginOptions:["useAccelerateEndpoint": useAccelerateEndpoint]))
        _ = try await task.value
        try await Amplify.Storage.remove(key: key)
    }

    /// Given: A data object.
    /// When: It's uploaded with acceleration misconfigured.
    /// Then: The operation fails.
    func testUploadDataWithAccelerateDisabledExplicitlyToWrongType() async throws {
        let key = UUID().uuidString
        let data = try XCTUnwrap(key.data(using: .utf8))
        do {
            let task = Amplify.Storage.uploadData(key: key,
                                                  data: data,
                                                  options: .init(pluginOptions:["useAccelerateEndpoint": "false"]))
            _ = try await task.value
            XCTFail("Expecting error from bogus useAccelerateEndpoint value type (String)")
            try await Amplify.Storage.remove(key: key)
        } catch {
            XCTAssertNotNil(error)
        }
    }

    /// Given: A file.
    /// When: It's uploaded with acceleration turned-off explicity.
    /// Then: The operation completes successfully.
    func testUploadFile() async throws {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"

        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: key.data(using: .utf8), attributes: nil)
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        let task = Amplify.Storage.uploadFile(key: key,
                                              local: fileURL,
                                              options: .init(pluginOptions:["useAccelerateEndpoint": useAccelerateEndpoint]))
        _ = try await task.value
        try await Amplify.Storage.remove(key: key)
    }

    /// Given: A large data object.
    /// When: It's uploaded with acceleration turned-off explicity.
    /// Then: The operation completes successfully.
    func testUploadLargeData() async throws {
        let key = UUID().uuidString
        let task = Amplify.Storage.uploadData(key: key,
                                              data: AWSS3StoragePluginTestBase.largeDataObject,
                                              options: .init(pluginOptions:["useAccelerateEndpoint": useAccelerateEndpoint]))
        _ = try await task.value
        try await Amplify.Storage.remove(key: key)
    }

    /// Given: An object in storage.
    /// When: It's downloaded with acceleration turned-off explicity.
    /// Then: The operation completes successfully with the data retrieved.
    func testDownloadDataToMemory() async throws {
        let key = UUID().uuidString
        let data = try XCTUnwrap(key.data(using: .utf8))
        let uploadTask = Amplify.Storage.uploadData(key: key,
                                                    data: data,
                                                    options: .init(pluginOptions:["useAccelerateEndpoint": useAccelerateEndpoint]))
        _ = try await uploadTask.value

        let downloadTask = Amplify.Storage.downloadData(key: key,
                                                        options: .init(pluginOptions:["useAccelerateEndpoint": useAccelerateEndpoint]))
        let downloadedData = try await downloadTask.value
        XCTAssertEqual(downloadedData, data)

        try await Amplify.Storage.remove(key: key)
    }
}
