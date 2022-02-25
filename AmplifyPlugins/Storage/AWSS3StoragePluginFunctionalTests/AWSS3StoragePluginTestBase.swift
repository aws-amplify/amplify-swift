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

    static let largeDataObject = Data(repeating: 0xff, count: 1_024 * 1_024 * 6) // 6MB

    static var user1: String = "integTest\(UUID().uuidString)"
    static var user2: String = "integTest\(UUID().uuidString)"
    static var password: String = "P123@\(UUID().uuidString)"
    static var email1 = UUID().uuidString + "@" + UUID().uuidString + ".com"
    static var email2 = UUID().uuidString + "@" + UUID().uuidString + ".com"

    static var isFirstUserSignedUp = false
    static var isSecondUserSignedUp = false

    override func setUp() {
        do {
            Amplify.reset()
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: AWSS3StoragePluginTestBase.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
            signUp()
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

    func signUp() {
        guard !AWSS3StoragePluginTestBase.isFirstUserSignedUp,
              !AWSS3StoragePluginTestBase.isSecondUserSignedUp else {
            return
        }

        let registerFirstUserComplete = expectation(description: "register completed")
        let registerSecondUserComplete = expectation(description: "register completed")
        AuthSignInHelper.signUpUser(
            username: AWSS3StoragePluginTestBase.user1,
            password: AWSS3StoragePluginTestBase.password,
            email: AWSS3StoragePluginTestBase.email1) { didSucceed, error in
                if didSucceed {
                    registerFirstUserComplete.fulfill()
                    AWSS3StoragePluginTestBase.isFirstUserSignedUp = true
                } else {
                    XCTFail("Failed to Sign up user \(error)")
                }
        }

        AuthSignInHelper.signUpUser(
            username: AWSS3StoragePluginTestBase.user2,
            password: AWSS3StoragePluginTestBase.password,
            email: AWSS3StoragePluginTestBase.email2) { didSucceed, error in
                if didSucceed {
                    registerSecondUserComplete.fulfill()
                    AWSS3StoragePluginTestBase.isSecondUserSignedUp = true
                } else {
                    XCTFail("Failed to Sign up user \(error)")
                }
        }

        wait(for: [registerFirstUserComplete, registerSecondUserComplete], timeout: TestCommonConstants.networkTimeout)

    }
}
