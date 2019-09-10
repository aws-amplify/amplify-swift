//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import Amplify
import AWSS3StoragePlugin
import AWSS3
import AWSCognitoIdentityProvider

class AWSS3StoragePluginTestBase: XCTestCase {

    let bucket = "swift6a3ad8b2b9f4402187f051de89548cc0-devo"
    let region = "us-east-1"

    override func setUp() {
        // Set up AWSMobileClient
        // Once https://github.com/aws-amplify/aws-sdk-ios/pull/1812 is done, we can add code like/
        // AWSInfo.configure(values we pass in), can even read from awsconfiguration.json or amplifyconfiguration.json.
        let mobileClientIsInitialized = expectation(description: "AWSMobileClient is initialized")
        AWSMobileClient.sharedInstance().initialize { (userState, error) in
            guard error == nil else {
                XCTFail("Error initializing AWSMobileClient. Error: \(error!.localizedDescription)")
                return
            }
            guard let userState = userState else {
                XCTFail("userState is unexpectedly empty initializing AWSMobileClient")
                return
            }
            if userState != UserState.signedOut {
                AWSMobileClient.sharedInstance().signOut()
            }
            mobileClientIsInitialized.fulfill()
        }
        wait(for: [mobileClientIsInitialized], timeout: 100)
        print("AWSMobileClient Initialized")

        // Set up Amplify storage configuration

        let storageConfig = StorageCategoryConfiguration(
            plugins: [
                "AWSS3StoragePlugin": [
                    "Bucket": bucket,
                    "Region": region
                ]
            ]
        )

        // TODO: Set up Amplify Hub configuration, and others like logging, auth
        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)
        //TODO: let amplifyConfig = AmplifyConfiguration(analytics: nil, api: nil, hub: hubConfig, logging: nil, storage: storageConfig)

        // Set up Amplify
        do {
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify")
        }
        print("Amplify initialized")
    }

    override func tearDown() {
        print("Amplify reset")
        Amplify.reset()
        sleep(5)
    }

    // MARK: Common Helper functions
    
    func putData(key: String, dataString: String) {
        putData(key: key, data: dataString.data(using: .utf8)!)
    }

    func putData(key: String, data: Data) {
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.put(key: key, data: data, options: nil) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }
}
