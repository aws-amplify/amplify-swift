//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable @_spi(InternalAmplifyConfiguration) import Amplify
@testable import AmplifyTestCommon
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
@testable import AWSPinpointAnalyticsPlugin
import XCTest

class AWSPinpointAnalyticsPluginConfigureTests: AWSPinpointAnalyticsPluginTestBase {
    
    override func setUp() async throws {
        AWSPinpointFactory.credentialIdentityResolver = MockCredentialsProvider()
        try await super.setUp()
    }
    
    // MARK: Plugin Key test

    func testPluginKey() {
        let pluginKey = analyticsPlugin.key
        XCTAssertEqual(pluginKey, "awsPinpointAnalyticsPlugin")
    }

    // MARK: Configuration tests

    func testConfigureSuccess() {
        let appId = JSONValue(stringLiteral: testAppId)
        let region = JSONValue(stringLiteral: testRegion)
        let autoFlushInterval = JSONValue(integerLiteral: Int(testAutoFlushInterval))
        let trackAppSession = JSONValue(booleanLiteral: false)
        let autoSessionTrackingInterval = JSONValue(integerLiteral: Int(testAutoSessionTrackingInterval))

        let pinpointAnalyticsPluginConfiguration = JSONValue(
            dictionaryLiteral:
            (AWSPinpointAnalyticsPluginConfiguration.appIdConfigKey, appId),
            (AWSPinpointAnalyticsPluginConfiguration.regionConfigKey, region)
        )

        let regionConfiguration = JSONValue(dictionaryLiteral:
            (AWSPinpointAnalyticsPluginConfiguration.regionConfigKey, region))

        let analyticsPluginConfig = JSONValue(
            dictionaryLiteral:
            (AWSPinpointAnalyticsPluginConfiguration.pinpointAnalyticsConfigKey, pinpointAnalyticsPluginConfiguration),
            (AWSPinpointAnalyticsPluginConfiguration.pinpointTargetingConfigKey, regionConfiguration),
            (AWSPinpointAnalyticsPluginConfiguration.autoFlushEventsIntervalKey, autoFlushInterval),
            (AWSPinpointAnalyticsPluginConfiguration.trackAppSessionsKey, trackAppSession),
            (AWSPinpointAnalyticsPluginConfiguration.autoSessionTrackingIntervalKey, autoSessionTrackingInterval)
        )

        do {
            let analyticsPlugin = AWSPinpointAnalyticsPlugin()
            try analyticsPlugin.configure(using: analyticsPluginConfig)

            XCTAssertNotNil(analyticsPlugin.pinpoint)
            XCTAssertNotNil(analyticsPlugin.globalProperties)
            XCTAssertNotNil(analyticsPlugin.isEnabled)
            XCTAssertEqual(analyticsPlugin.options?.autoFlushEventsInterval, testAutoFlushInterval)
            XCTAssertEqual(analyticsPlugin.options?.trackAppSessions, false)
        } catch {
            XCTFail("Failed to configure analytics plugin")
        }
    }

    func testConfigure_OptionsOverride() {
        let appId = JSONValue(stringLiteral: testAppId)
        let region = JSONValue(stringLiteral: testRegion)
        let autoFlushInterval = JSONValue(integerLiteral: 30)
        let trackAppSession = JSONValue(booleanLiteral: false)
        let autoSessionTrackingInterval = JSONValue(integerLiteral: 40)

        let pinpointAnalyticsPluginConfiguration = JSONValue(
            dictionaryLiteral:
            (AWSPinpointAnalyticsPluginConfiguration.appIdConfigKey, appId),
            (AWSPinpointAnalyticsPluginConfiguration.regionConfigKey, region)
        )

        let regionConfiguration = JSONValue(dictionaryLiteral:
            (AWSPinpointAnalyticsPluginConfiguration.regionConfigKey, region))

        let analyticsPluginConfig = JSONValue(
            dictionaryLiteral:
            (AWSPinpointAnalyticsPluginConfiguration.pinpointAnalyticsConfigKey, pinpointAnalyticsPluginConfiguration),
            (AWSPinpointAnalyticsPluginConfiguration.pinpointTargetingConfigKey, regionConfiguration),
            (AWSPinpointAnalyticsPluginConfiguration.autoFlushEventsIntervalKey, autoFlushInterval),
            (AWSPinpointAnalyticsPluginConfiguration.trackAppSessionsKey, trackAppSession),
            (AWSPinpointAnalyticsPluginConfiguration.autoSessionTrackingIntervalKey, autoSessionTrackingInterval)
        )

        do {
            let analyticsPlugin = AWSPinpointAnalyticsPlugin(
                options: .init(
                    autoFlushEventsInterval: 50,
                    trackAppSessions: true))
            try analyticsPlugin.configure(using: analyticsPluginConfig)

            XCTAssertNotNil(analyticsPlugin.pinpoint)
            XCTAssertNotNil(analyticsPlugin.globalProperties)
            XCTAssertNotNil(analyticsPlugin.isEnabled)
            XCTAssertEqual(analyticsPlugin.options?.autoFlushEventsInterval, 50)
            XCTAssertEqual(analyticsPlugin.options?.trackAppSessions, true)
        } catch {
            XCTFail("Failed to configure analytics plugin")
        }
    }

    func testConfigureFailureForNilConfiguration() throws {
        let plugin = AWSPinpointAnalyticsPlugin()
        do {
            try plugin.configure(using: nil)
            XCTFail("Analytics configuration should not succeed")
        } catch {
            guard let pluginError = error as? PluginError,
                case .pluginConfigurationError = pluginError else {
                    XCTFail("Should throw invalidConfiguration exception. But received \(error) ")
                    return
            }
        }
    }

    // MARK: - AmplifyOutputsData Configuration tests

    func testConfigure_WithAmplifyOutputs() {
        let config = AmplifyOutputsData.init(analytics: .init(
            amazonPinpoint: .init(awsRegion: testRegion,
                                  appId: testAppId)))

        do {
            let analyticsPlugin = AWSPinpointAnalyticsPlugin()
            try analyticsPlugin.configure(using: config)

            XCTAssertNotNil(analyticsPlugin.pinpoint)
            XCTAssertNotNil(analyticsPlugin.globalProperties)
            XCTAssertNotNil(analyticsPlugin.isEnabled)

            // Verify default options when none are passed in with the plugin's instantiation
            XCTAssertEqual(analyticsPlugin.options?.autoFlushEventsInterval, AWSPinpointAnalyticsPlugin.Options.defaultAutoFlushEventsInterval)
            XCTAssertEqual(analyticsPlugin.options?.trackAppSessions, AWSPinpointAnalyticsPlugin.Options.defaultTrackAppSession)

        } catch {
            XCTFail("Failed to configure analytics plugin")
        }
    }

    func testConfigure_WithAmplifyOutputsAndOptions() {
        let config = AmplifyOutputsData.init(analytics: .init(
            amazonPinpoint: .init(awsRegion: testRegion,
                                  appId: testAppId)))

        do {
            let analyticsPlugin = AWSPinpointAnalyticsPlugin(options: .init(
                autoFlushEventsInterval: 100,
                trackAppSessions: false))
            try analyticsPlugin.configure(using: config)

            XCTAssertNotNil(analyticsPlugin.pinpoint)
            XCTAssertNotNil(analyticsPlugin.globalProperties)
            XCTAssertNotNil(analyticsPlugin.isEnabled)

            // Verify options override when passed in with the plugin's instantiation
            XCTAssertEqual(analyticsPlugin.options?.autoFlushEventsInterval, 100)
            XCTAssertEqual(analyticsPlugin.options?.trackAppSessions, false)

        } catch {
            XCTFail("Failed to configure analytics plugin")
        }
    }

}
