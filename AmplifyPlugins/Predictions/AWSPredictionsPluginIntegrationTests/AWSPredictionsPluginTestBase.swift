//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
@testable import Amplify
import AWSPredictionsPlugin

class AWSPredictionsPluginTestBase: XCTestCase {

    let region: JSONValue = "us-east-1"
    let networkTimeout = TimeInterval(180) // 180 seconds to wait before network timeouts

    override func setUp() {
        // Set up AWSMobileClient
        // Once https://github.com/aws-amplify/aws-sdk-ios/pull/1812 is done, we can add code like/
        // AWSInfo.configure(values we pass in), can even read from awsconfiguration.json or amplifyconfiguration.json.
        let mobileClientIsInitialized = expectation(description: "AWSMobileClient is initialized")
        AWSMobileClient.default().initialize { userState, error in
            guard error == nil else {
                XCTFail("Error initializing AWSMobileClient. Error: \(error!.localizedDescription)")
                return
            }
            guard let userState = userState else {
                XCTFail("userState is unexpectedly empty initializing AWSMobileClient")
                return
            }
            if userState != UserState.signedOut {
                AWSMobileClient.default().signOut()
            }
            mobileClientIsInitialized.fulfill()
        }
        wait(for: [mobileClientIsInitialized], timeout: networkTimeout)
        print("AWSMobileClient Initialized")

        // Set up Amplify predictions configuration

        let predictionsConfig = PredictionsCategoryConfiguration(
            plugins: [
                "AWSPredictionsPlugin": [
                    "Region": region
                ]
            ]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: predictionsConfig)

        // Set up Amplify
        do {
            try Amplify.add(plugin: AWSPredictionsPlugin())
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

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
