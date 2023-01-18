//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPinpoint

@testable import Amplify
@testable import AWSPinpointAnalyticsPlugin
import AWSCognitoAuthPlugin
import Network

final class AnalyticsStressTests: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/AWSAmplifyStressTests-amplifyconfiguration"
    static let analyticsPluginKey = "awsPinpointAnalyticsPlugin"
    let concurrencyLimit = 50
    
    override func setUp() {
        do {
            let config = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfiguration)
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSPinpointAnalyticsPlugin())
            try Amplify.configure(config)
        } catch {
            XCTFail("Failed to initialize and configure Amplify \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    // MARK: - Stress Tests
    
    /// - Given: Analytics plugin configured with valid configuration
    /// - When: 50 different events with 5 attributes are recorded simultaneously
    /// - Then: Operations are successful
    func testMultipleRecordEvent() async {
        let onlineExpectation = expectation(description: "Device is online")
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { newPath in
            if newPath.status == .satisfied {
                onlineExpectation.fulfill()
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "AWSPinpointAnalyticsPluginIntergrationTests.NetworkMonitor"))
        
        wait(for: [onlineExpectation], timeout: TestCommonConstants.networkTimeout)
        
        let recordExpectation = asyncExpectation(description: "Records are successfully recorded",
                                                 expectedFulfillmentCount: concurrencyLimit)
        for eventNumber in 0...concurrencyLimit {
            Task {
                let properties = ["eventPropertyStringKey1": "eventProperyStringValue1",
                                  "eventPropertyStringKey2": "eventProperyStringValue2",
                                  "eventPropertyStringKey3": "eventProperyStringValue3",
                                  "eventPropertyStringKey4": "eventProperyStringValue4",
                                  "eventPropertyStringKey5": "eventProperyStringValue5"] as [String: AnalyticsPropertyValue]
                let event = BasicAnalyticsEvent(name: "eventName" + String(eventNumber), properties: properties)
                Amplify.Analytics.record(event: event)
                await recordExpectation.fulfill()
            }
        }

        await waitForExpectations([recordExpectation], timeout: TestCommonConstants.networkTimeout)
    }
    
    /// - Given: Analytics plugin configured with valid configuration
    /// - When: 50 different events with 20 attributes are recorded simultaneously
    /// - Then: Operations are successful
    func testMultipleLargeRecordEventAndFlush() async {
        let onlineExpectation = expectation(description: "Device is online")
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { newPath in
            if newPath.status == .satisfied {
                onlineExpectation.fulfill()
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "AWSPinpointAnalyticsPluginIntergrationTests.NetworkMonitor"))
        
        wait(for: [onlineExpectation], timeout: TestCommonConstants.networkTimeout)
        
        let recordExpectation = asyncExpectation(description: "Records are successfully recorded",
                                                 expectedFulfillmentCount: concurrencyLimit)
        for eventNumber in 0...concurrencyLimit {
            Task {
                let properties = ["eventPropertyStringKey1": "eventProperyStringValue1",
                                  "eventPropertyStringKey2": "eventProperyStringValue2",
                                  "eventPropertyStringKey3": "eventProperyStringValue3",
                                  "eventPropertyStringKey4": "eventProperyStringValue4",
                                  "eventPropertyStringKey5": "eventProperyStringValue5",
                                  "eventPropertyIntKey1": 123,
                                  "eventPropertyIntKey2": 123,
                                  "eventPropertyIntKey3": 123,
                                  "eventPropertyIntKey4": 123,
                                  "eventPropertyIntKey5": 123,
                                  "eventPropertyDoubleKey1": 12.34,
                                  "eventPropertyDoubleKey2": 12.34,
                                  "eventPropertyDoubleKey3": 12.34,
                                  "eventPropertyDoubleKey4": 12.34,
                                  "eventPropertyDoubleKey5": 12.34,
                                  "eventPropertyBoolKey1": true,
                                  "eventPropertyBoolKey2": true,
                                  "eventPropertyBoolKey3": true,
                                  "eventPropertyBoolKey4": true,
                                  "eventPropertyBoolKey5": true] as [String: AnalyticsPropertyValue]
                let event = BasicAnalyticsEvent(name: "eventName" + String(eventNumber), properties: properties)
                Amplify.Analytics.record(event: event)
                await recordExpectation.fulfill()
            }
        }

        await waitForExpectations([recordExpectation], timeout: TestCommonConstants.networkTimeout)
    }

}
