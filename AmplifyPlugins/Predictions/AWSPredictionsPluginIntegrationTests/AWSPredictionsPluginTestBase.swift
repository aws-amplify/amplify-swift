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

    let region: JSONValue = "us-west-2"
    let networkTimeout = TimeInterval(180) // 180 seconds to wait before network timeouts

    override func setUp() {
        setupMobileClient()
        setupAmplify()
    }

    override func tearDown() {
        sleep(1)
        print("Amplify reset")
        Amplify.reset()
    }

    private func setupAmplify() {
        // Set up Amplify predictions configuration
        let predictionsConfig = PredictionsCategoryConfiguration(
            plugins: [
                "AWSPredictionsPlugin": [
                    "defaultRegion": region,
                    "identify": [
                        "identifyEntities": [
                        "maxFaces": 50,
                        "collectionId": "", //no collectionid
                        "region": region
                        ]
                    ]
                ]
            ]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: predictionsConfig)

        // Set up Amplify
        do {
            try Amplify.add(plugin: AWSPredictionsPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify - \(error)")
        }
        print("Amplify initialized")
    }

    private func setupMobileClient() {
        // Set up AWSMobileClient
        let testBundle = Bundle(for: type(of: self))
        guard let configurationFile = testBundle.url(forResource: "awsconfiguration", withExtension: "json") else {
            XCTFail("Could not find the configuration file. Please check awsconfiguration.json file is in the path.")
            return
        }
        guard let configurationData = try? Data(contentsOf: configurationFile) else {
            XCTFail("Could not read configuration data.")
            return
        }
        guard let configurationJson = try? JSONSerialization.jsonObject(with: configurationData)
            as? [String: Any] else {

            XCTFail("Could not parse the configuration data.")
            return
        }
        AWSInfo.configureDefaultAWSInfo(configurationJson)

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
    }
}
