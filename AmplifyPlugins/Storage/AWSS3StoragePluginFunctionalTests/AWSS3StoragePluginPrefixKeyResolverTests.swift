//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSS3StoragePlugin

@testable import Amplify
@testable import AmplifyTestCommon
import AWSCognitoAuthPlugin

class AWSS3StoragePluginKeyResolverTests: XCTestCase {

    static let amplifyConfiguration = "AWSS3StoragePluginTests-amplifyconfiguration"

    override func setUp() {
        Amplify.reset()
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin(
                configuration: .prefixResolver(MockGuestOverridePrefixResolver())))
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: AWSS3StoragePluginTestBase.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
        // Unforunately, `sleep` has been added here to get more consistent test runs. The SDK will be used with
        // same key to create a URLSession. The `sleep` helps avoid the error:
        // ```
        // A background URLSession with identifier
        // com.amazonaws.AWSS3TransferUtility.Default.Identifier.awsS3StoragePlugin already exists!`
        // ```
        // TODO: Remove in the future when the plugin no longer depends on the SDK and have addressed this problem.
        sleep(5)
    }

    // This mock resolver shows how to perform an upload to the `.guest` access level with a custom prefix value.
    struct MockGuestOverridePrefixResolver: AWSS3PluginPrefixResolver {
        func resolvePrefix(for accessLevel: StorageAccessLevel,
                           targetIdentityId: String?,
                           completion: @escaping (Result<String, StorageError>) -> Void) {
            switch accessLevel {
            case .guest:
                completion(.success("public/customPublic/"))
            case .protected:
                completion(.failure(.configuration("`.protected` StorageAccessLevel is not used", "", nil)))
            case .private:
                completion(.failure(.configuration("`.protected` StorageAccessLevel is not used", "", nil)))
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
    func testUploadListDownload() {
        let key = UUID().uuidString
        let data = key.data(using: .utf8)!
        let uploadCompleted = expectation(description: "upload completed")

        _ = Amplify.Storage.uploadData(key: key, data: data) { event in
            switch event {
            case .success:
                uploadCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        wait(for: [uploadCompleted], timeout: TestCommonConstants.networkTimeout)

        let listCompleted = expectation(description: "list completed")
        let listOptions = StorageListRequest.Options(path: key)
        var resultItem: StorageListResult.Item?
        _ = Amplify.Storage.list(options: listOptions) { event in
            switch event {
            case .success(let result):
                XCTAssertNotNil(result)
                XCTAssertNotNil(result.items)
                XCTAssertEqual(result.items.count, 1)
                resultItem = result.items.first
                listCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        wait(for: [listCompleted], timeout: TestCommonConstants.networkTimeout)

        guard let item = resultItem else {
            XCTFail("Failed to retrieve key from List API")
            return
        }
        XCTAssertEqual(item.key, key)
        let downloadCompleted = expectation(description: "download completed")
        _ = Amplify.Storage.downloadData(key: item.key) { event in
            switch event {
            case .success(let data):
                XCTAssertNotNil(data)
                downloadCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        wait(for: [downloadCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    /// Storage operations (upload, remove, download) performed using a developer defined prefixkey resolver.
    ///
    /// - Given: Operations for default access level (.guest) and a mock key resolver in plugin configuration.
    /// - When:
    ///    - Upload, Remove, Download
    /// - Then:
    ///    - The removed file should not exist with accurate error
    ///
    func testUploadRemoveDownload() {
        let key = UUID().uuidString
        let data = key.data(using: .utf8)!
        let uploadCompleted = expectation(description: "upload completed")

        _ = Amplify.Storage.uploadData(key: key, data: data) { event in
            switch event {
            case .success:
                uploadCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        wait(for: [uploadCompleted], timeout: TestCommonConstants.networkTimeout)

        let removeCompleted = expectation(description: "remove completed")
        Amplify.Storage.remove(key: key) { event in
            switch event {
            case .success(let result):
                XCTAssertNotNil(result)
                removeCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        wait(for: [removeCompleted], timeout: TestCommonConstants.networkTimeout)

        let downloadCompleted = expectation(description: "download completed")
        _ = Amplify.Storage.downloadData(key: key) { event in
            switch event {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                guard case .keyNotFound = error else {
                    XCTFail("Should have failed with .keyNotFound")
                    return
                }
                downloadCompleted.fulfill()
            }
        }

        wait(for: [downloadCompleted], timeout: TestCommonConstants.networkTimeout)
    }
}
