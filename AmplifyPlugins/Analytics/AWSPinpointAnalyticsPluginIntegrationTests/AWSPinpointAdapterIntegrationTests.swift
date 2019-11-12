//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPinpointAnalyticsPlugin
import AWSMobileClient

class AWSPinpointAdapterIntegrationTests: XCTestCase {

    let appId = "56e6f06fd4f244c6b202bc327bd3b4e6"
    let region = "us-east-1"
    let targetingRegion = "us-east-1"

    override func setUp() {
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
    }

    func testAWSPinpointAdapterSuccess() {
        do {
            let pinpointAdapter = try AWSPinpointAdapter(pinpointAnalyticsAppId: appId,
                                                         pinpointAnalyticsRegion: region.aws_regionTypeValue(),
                                                         pinpointTargetingRegion: targetingRegion.aws_regionTypeValue(),
                                                         cognitoCredentialsProvider: AWSMobileClient.default())
            XCTAssertNotNil(pinpointAdapter)
            XCTAssertNotNil(pinpointAdapter.pinpoint)
            XCTAssertNotNil(pinpointAdapter.pinpoint.analyticsClient)
            XCTAssertNotNil(pinpointAdapter.pinpoint.targetingClient)
            XCTAssertNotNil(pinpointAdapter.pinpoint.sessionClient)
            XCTAssertNotNil(pinpointAdapter.pinpoint.configuration)
            XCTAssertFalse(pinpointAdapter.pinpoint.configuration.enableAutoSessionRecording)
        } catch {
            XCTFail("should not have thrown exception")
        }
    }
}
