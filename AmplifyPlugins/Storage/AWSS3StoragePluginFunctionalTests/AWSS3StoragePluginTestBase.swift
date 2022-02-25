//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
import AWSS3StoragePlugin
@testable import AmplifyTestCommon
import AWSCognitoAuthPlugin

class AWSS3StoragePluginTestBase: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/AWSS3StoragePluginTests-amplifyconfiguration"
    static let credentials = "testconfiguration/AWSS3StoragePluginTests-credentials"

    static let largeDataObject = Data(repeating: 0xff, count: 1_024 * 1_024 * 6) // 6MB

    static var user1: String!
    static var user2: String!
    static var password: String!

    static override func setUp() {
        do {
            let credentials = try TestConfigHelper
                .retrieveCredentials(forResource: AWSS3StoragePluginTestBase.credentials)

            guard let user1 = credentials["user1"],
                let user2 = credentials["user2"],
                let password = credentials["password"] else {
                XCTFail("Missing credentials.json data")
                return
            }
            AWSS3StoragePluginTestBase.user1 = user1
            AWSS3StoragePluginTestBase.user2 = user2
            AWSS3StoragePluginTestBase.password = password
        } catch {
            XCTFail("Failed to initialize test set up \(error)")
        }
    }

    override func setUp() {
        do {
            Amplify.reset()
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
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

    // MARK: Common Helper functions

    func uploadData(key: String, dataString: String) {
        uploadData(key: key, data: dataString.data(using: .utf8)!)
    }

    func uploadData(key: String, data: Data) {
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.uploadData(key: key, data: data, options: nil) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }

    static func getBucketFromConfig(forResource: String) throws -> String {
        let data = try TestConfigHelper.retrieve(forResource: forResource)
        let json = try JSONDecoder().decode(JSONValue.self, from: data)
        guard let bucket = json["storage"]?["plugins"]?["awsS3StoragePlugin"]?["bucket"] else {
            throw "Could not retrieve bucket from config"
        }

        guard case let .string(bucketValue) = bucket else {
            throw "bucket is not a string value"
        }

        return bucketValue
    }
}
