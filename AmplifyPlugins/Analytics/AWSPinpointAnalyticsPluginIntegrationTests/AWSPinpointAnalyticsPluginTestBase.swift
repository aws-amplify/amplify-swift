//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
import AWSMobileClient
import AWSPinpointAnalyticsPlugin
import XCTest

class AWSPinpointAnalyticsPluginTestBase: XCTestCase {
    let appId: JSONValue = "56e6f06fd4f244c6b202bc327bd3b4e6"
    let region: JSONValue = "us-east-1"
    let targetingRegion: JSONValue = "us-east-1"

    override func setUp() async throws {
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
        wait(for: [mobileClientIsInitialized], timeout: 100)
        print("AWSMobileClient Initialized")

        let analyticsConfig = AnalyticsCategoryConfiguration(
            plugins: [
                "awsPinpointAnalyticsPlugin": [
                    "pinpointAnalytics": [
                        "appId": appId,
                        "region": region
                    ],
                    "pinpointTargeting": [
                        "region": targetingRegion
                    ],
                    "autoFlushEventsInterval": 10,
                    "trackAppSessions": true,
                    "autoSessionTrackingInterval": 2
                ]
            ])

        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        do {
            try Amplify.add(plugin: AWSPinpointAnalyticsPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify")
        }

        print("Amplify initialized")
    }

    override func tearDown() async throws {
        print("Amplify reset")
        await Amplify.reset()
    }
}
