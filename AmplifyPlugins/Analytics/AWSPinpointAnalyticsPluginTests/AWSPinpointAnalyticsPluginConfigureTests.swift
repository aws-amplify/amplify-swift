//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSPinpointAnalyticsPlugin

class AWSPinpointAnalyticsPluginConfigureTests: AWSPinpointAnalyticsPluginTestBase {

    // MARK: Plugin Key test
    func testPluginKey() {
        let pluginKey = analyticsPlugin.key
        XCTAssertEqual(pluginKey, "awsPinpointAnalyticsPlugin")
    }

    // MARK: Configuration tests

    func testConfigureSuccess() {
        let appId = JSONValue.init(stringLiteral: testAppId)
        let region = JSONValue.init(stringLiteral: testRegion)
        let autoFlushInterval = JSONValue.init(integerLiteral: testAutoFlushInterval)
        let trackAppSession = JSONValue.init(booleanLiteral: testTrackAppSession)
        let autoSessionTrackingInterval = JSONValue.init(integerLiteral: testAutoSessionTrackingInterval)

        let pinpointAnalyticsPluginConfiguration = JSONValue.init(
            dictionaryLiteral:
            (AWSPinpointAnalyticsPluginConfiguration.appIdConfigKey, appId),
            (AWSPinpointAnalyticsPluginConfiguration.regionConfigKey, region))

        let regionConfiguration = JSONValue.init(dictionaryLiteral:
            (AWSPinpointAnalyticsPluginConfiguration.regionConfigKey, region))

        let analyticsPluginConfig = JSONValue.init(
            dictionaryLiteral:
            (AWSPinpointAnalyticsPluginConfiguration.pinpointAnalyticsConfigKey, pinpointAnalyticsPluginConfiguration),
            (AWSPinpointAnalyticsPluginConfiguration.pinpointTargetingConfigKey, regionConfiguration),
            (AWSPinpointAnalyticsPluginConfiguration.autoFlushEventsIntervalKey, autoFlushInterval),
            (AWSPinpointAnalyticsPluginConfiguration.trackAppSessionsKey, trackAppSession),
            (AWSPinpointAnalyticsPluginConfiguration.autoSessionTrackingIntervalKey, autoSessionTrackingInterval))

        do {
            let analyticsPlugin = AWSPinpointAnalyticsPlugin()
            try analyticsPlugin.configure(using: analyticsPluginConfig)

            XCTAssertNotNil(analyticsPlugin.pinpoint)
            XCTAssertNotNil(analyticsPlugin.authService)
            XCTAssertNotNil(analyticsPlugin.autoFlushEventsTimer)
            XCTAssertNotNil(analyticsPlugin.appSessionTracker)
            XCTAssertNotNil(analyticsPlugin.globalProperties)
            XCTAssertNotNil(analyticsPlugin.isEnabled)
        } catch {
           XCTFail("Failed to configure analytics plugin")
        }
    }
}
