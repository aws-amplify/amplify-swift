//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable @_spi(InternalAmplifyConfiguration) import Amplify
import XCTest
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
@testable import AWSPinpointAnalyticsPlugin

// swiftlint:disable:next type_name
class AWSPinpointAnalyticsPluginAmplifyOutputsConfigurationTests: XCTestCase {
    let testAppId = "testAppId"
    let appId = "testAppId"
    let testRegion = "us-east-1"
    let region: JSONValue = "us-east-1"
    let testAutoFlushInterval: UInt = 300
    let autoFlushInterval: JSONValue = 300
    let testTrackAppSession = false
    let trackAppSession: JSONValue = false
    let testAutoSessionTrackingInterval: UInt = 100
    let autoSessionTrackingInterval: JSONValue = 100
    let pinpointAnalyticsPluginConfiguration = JSONValue(
        dictionaryLiteral:
        (AWSPinpointAnalyticsPluginConfiguration.appIdConfigKey, "testAppId"),
        (AWSPinpointAnalyticsPluginConfiguration.regionConfigKey, "us-east-1")
    )

    func testConfiguration_Success() throws {
        let config = AmplifyOutputsData(analytics: .init(amazonPinpoint: .init(awsRegion: testRegion, appId: appId)))
        let result = try AWSPinpointAnalyticsPluginConfiguration(config, options: .init())
        XCTAssertNotNil(result)
        XCTAssertEqual(result.appId, testAppId)
        XCTAssertEqual(result.region, testRegion)
        XCTAssertEqual(result.options.autoFlushEventsInterval,
                       AWSPinpointAnalyticsPlugin.Options.defaultAutoFlushEventsInterval)
        XCTAssertEqual(result.options.trackAppSessions,
                       AWSPinpointAnalyticsPlugin.Options.defaultTrackAppSession)
        XCTAssertEqual(result.options.autoSessionTrackingInterval,
                       AWSPinpointAnalyticsPlugin.Options.defaultAutoSessionTrackingInterval)
    }

    func testConfiguration_OptionsOverride() throws {
        let config = AmplifyOutputsData(analytics: .init(amazonPinpoint: .init(awsRegion: testRegion, appId: appId)))
        let result = try AWSPinpointAnalyticsPluginConfiguration(
            config,
            options: .init(autoFlushEventsInterval: 100,
                           trackAppSessions: false,
                           autoSessionTrackingInterval: 200))
        XCTAssertNotNil(result)
        XCTAssertEqual(result.appId, testAppId)
        XCTAssertEqual(result.region, testRegion)
        XCTAssertEqual(result.options.autoFlushEventsInterval, 100)
        XCTAssertFalse(result.options.trackAppSessions)
        XCTAssertEqual(result.options.autoSessionTrackingInterval, 200)
    }

    func testConfiguration_throwsMissingAnalytics() {
        do {
            let config = AmplifyOutputsData(analytics: nil)
            _ = try AWSPinpointAnalyticsPluginConfiguration(config, options: .init())
        } catch {
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected to catch PluginError.pluginConfigurationError.")
                return
            }
            XCTAssertEqual(errorDescription,
                           AnalyticsPluginErrorConstant.missingAnalyticsCategoryConfiguration.errorDescription)
        }
    }

    func testConfiguration_throwAmazonPinpoint() {
        do {
            let config = AmplifyOutputsData(analytics: .init(amazonPinpoint: nil))
            _ = try AWSPinpointAnalyticsPluginConfiguration(config, options: .init())
        } catch {
            guard case let PluginError.pluginConfigurationError(errorDescription, _, _) = error else {
                XCTFail("Expected to catch PluginError.pluginConfigurationError.")
                return
            }
            XCTAssertEqual(errorDescription,
                           AnalyticsPluginErrorConstant.missingAmazonPinpointConfiguration.errorDescription)
        }
    }

}

