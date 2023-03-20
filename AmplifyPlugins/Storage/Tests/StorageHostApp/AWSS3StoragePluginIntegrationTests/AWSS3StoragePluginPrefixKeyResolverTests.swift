//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSS3StoragePlugin

@testable import Amplify
import AWSCognitoAuthPlugin

class AWSS3StoragePluginKeyResolverTests: AWSS3StoragePluginTestBase {

    override func setUp() async throws {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin(configuration: .prefixResolver(MockGuestOverridePrefixResolver())))
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: AWSS3StoragePluginTestBase.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify \(error)")
        }
    }

    // This mock resolver shows how to perform an upload to the `.guest` access level with a custom prefix value.
    struct MockGuestOverridePrefixResolver: AWSS3PluginPrefixResolver {
        func resolvePrefix(for accessLevel: StorageAccessLevel, targetIdentityId: String?) async throws -> String {
            switch accessLevel {
            case .guest:
                return "public/customPublic/"
            case .protected:
                throw StorageError.configuration("`.protected` StorageAccessLevel is not used", "", nil)
            case .private:
                throw StorageError.configuration("`.protected` StorageAccessLevel is not used", "", nil)
            }
        }
    }

    /// Storage operations (upload, list, download) performed using a developer defined prefixKey resolver.
    ///
    /// - Given: Operations for default access level (.guest) and a mock key resolver in plugin configuration.
    /// - When:
    ///    - Upload, then List with path equal to the uniquely generated`key` to the single item
    ///    - Download using the key from the List API
    /// - Then:
    ///    - Download is successful
    ///
    func testUploadListDownload() async {
        let key = UUID().uuidString
        let data = key.data(using: .utf8)!
        let uploadCompleted = asyncExpectation(description: "upload completed")
        await wait(with: uploadCompleted) {
            _ = try await Amplify.Storage.uploadData(key: key, data: data).value
        }

        let listCompleted = asyncExpectation(description: "list completed")
        let listOptions = StorageListRequest.Options(path: key)
        let result = await wait(with: listCompleted) {
            return try await Amplify.Storage.list(options: listOptions)
        }

        guard let items = result?.items else {
            XCTFail("Failed to list items")
            return
        }
        XCTAssertEqual(items.count, 1)

        guard let item = items.first else {
            XCTFail("Failed to retrieve key from List API")
            return
        }
        XCTAssertEqual(item.key, key)

        let downloadCompleted = asyncExpectation(description: "download completed")
        let downloadedData = await wait(with: downloadCompleted) {
            return try await Amplify.Storage.downloadData(key: item.key).value
        }

        XCTAssertNotNil(downloadedData)
        
        // Remove the key
        await remove(key: key)
    }

    /// Storage operations (upload, remove, download) performed using a developer defined prefixkey resolver.
    ///
    /// - Given: Operations for default access level (.guest) and a mock key resolver in plugin configuration.
    /// - When:
    ///    - Upload, Remove, Download
    /// - Then:
    ///    - The removed file should not exist with accurate error
    ///
    func testUploadRemoveDownload() async {
        let key = UUID().uuidString
        let data = key.data(using: .utf8)!

        let done = asyncExpectation(description: "done")

        Task {
            do {
                let uploadResult = try await Amplify.Storage.uploadData(key: key, data: data).value
                XCTAssertEqual(uploadResult, key)
                let removeResult = try await Amplify.Storage.remove(key: key)
                XCTAssertEqual(removeResult, key)
                let notDone = asyncExpectation(description: "not done", isInverted: true)
                let caughtError = asyncExpectation(description: "caught error")
                do {
                    _ = try await Amplify.Storage.downloadData(key: key).value
                    await notDone.fulfill()
                } catch {
                    guard case .keyNotFound = error as? StorageError else {
                        XCTFail("Should have failed with .keyNotFound, got \(error)")
                        return
                    }
                    await caughtError.fulfill()
                }

                await waitForExpectations([notDone], timeout: 0.25)
                await waitForExpectations([caughtError])
            } catch {
                XCTFail("Error: \(error)")
            }
            await done.fulfill()
        }

        await waitForExpectations([done], timeout: TestCommonConstants.networkTimeout)
    }
}
