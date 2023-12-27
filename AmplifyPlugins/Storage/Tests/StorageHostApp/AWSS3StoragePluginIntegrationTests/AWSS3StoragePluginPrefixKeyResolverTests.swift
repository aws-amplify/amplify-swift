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
            try Amplify.configure()
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
    func testUploadListDownload() async throws {
        let key = UUID().uuidString
        let data = Data(key.utf8)
        let uploadCompleted = expectation(description: "upload completed")
        Task {
            do {
                _ = try await Amplify.Storage.uploadData(key: key, data: data).value
                uploadCompleted.fulfill()
            } catch {
                XCTFail("Failed with \(error)")
            }
        }
        await fulfillment(of: [uploadCompleted])

        let listOptions = StorageListRequest.Options(path: key)
        let listResult = try await Amplify.Storage.list(options: listOptions)
        XCTAssertEqual(listResult.items.count, 1)
        let itemKey = try XCTUnwrap(listResult.items.first?.key)
        XCTAssertEqual(itemKey, key)

        let downloadCompleted = expectation(description: "download completed")
        Task {
            let downloadedData = try await Amplify.Storage.downloadData(key: itemKey).value
            XCTAssertNotNil(downloadedData)
            downloadCompleted.fulfill()
        }
        await fulfillment(of: [downloadCompleted])
        
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
        let data = Data(key.utf8)
        let done = expectation(description: "done")

        Task {
            do {
                let uploadResult = try await Amplify.Storage.uploadData(key: key, data: data).value
                XCTAssertEqual(uploadResult, key)
                let removeResult = try await Amplify.Storage.remove(key: key)
                XCTAssertEqual(removeResult, key)
                let notDone = expectation(description: "not done")
                notDone.isInverted = true
                let caughtError = expectation(description: "caught error")
                do {
                    _ = try await Amplify.Storage.downloadData(key: key).value
                    notDone.fulfill()
                } catch {
                    guard case .keyNotFound = error as? StorageError else {
                        XCTFail("Should have failed with .keyNotFound, got \(error)")
                        return
                    }
                    caughtError.fulfill()
                }

                await fulfillment(of: [notDone], timeout: 0.25)
                await fulfillment(of: [caughtError])
            } catch {
                XCTFail("Error: \(error)")
            }
            done.fulfill()
        }

        await fulfillment(of: [done], timeout: TestCommonConstants.networkTimeout)
    }
}
