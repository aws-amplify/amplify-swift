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
@testable import AmplifyTestCommon

// swiftlint:disable:next type_name
class AWSPinpointAnalyticsPluginIntergrationTests: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/AWSPinpointAnalyticsPluginIntegrationTests-amplifyconfiguration"
    static let analyticsPluginKey = "awsPinpointAnalyticsPlugin"

    override func setUp() {
        do {
            let config = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: AWSPinpointAnalyticsPluginIntergrationTests.amplifyConfiguration)
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSPinpointAnalyticsPlugin())
            try Amplify.configure(config)
        } catch {
            XCTFail("Failed to initialize and configure Amplify \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testIdentifyUser() {
        let userId = "userId"
        let identifyUserEvent = expectation(description: "Identify User event was received on the hub plugin")
        _ = Amplify.Hub.listen(to: .analytics, isIncluded: nil) { payload in
            print(payload)
            if payload.eventName == HubPayload.EventName.Analytics.identifyUser {
                guard let data = payload.data as? (String, AnalyticsUserProfile?) else {
                    XCTFail("Missing data")
                    return
                }

                XCTAssertNotNil(data)
                XCTAssertEqual(data.0, userId)
                identifyUserEvent.fulfill()
            }
        }

        let location = AnalyticsUserProfile.Location(latitude: 47.606209,
                                                     longitude: -122.332069,
                                                     postalCode: "98122",
                                                     city: "Seattle",
                                                     region: "WA",
                                                     country: "USA")
        let properties = ["userPropertyStringKey": "userProperyStringValue",
                          "userPropertyIntKey": 123,
                          "userPropertyDoubleKey": 12.34,
                          "userPropertyBoolKey": true] as [String: AnalyticsPropertyValue]
        let userProfile = AnalyticsUserProfile(name: "name",
                                               email: "email",
                                               plan: "plan",
                                               location: location,
                                               properties: properties)
        Amplify.Analytics.identifyUser(userId, withProfile: userProfile)

        wait(for: [identifyUserEvent], timeout: TestCommonConstants.networkTimeout)

        // Remove userId from the current endpoint
        let targetingClient = escapeHatch().targetingClient
        let currentProfile = targetingClient.currentEndpointProfile()
        currentProfile.user?.userId = ""
        targetingClient.update(currentProfile)
    }

    /// Run this test when the number of endpoints for the userId exceeds the limit.
    /// The profile should have permissions to run the "mobiletargeting:DeleteUserEndpoints" action.
    func skip_testDeleteEndpointsForUser() throws {
        let userId = "userId"
        let escapeHatch = escapeHatch()
        let applicationId = escapeHatch.configuration.appId
        guard let targetingConfiguration = escapeHatch.configuration.targetingServiceConfiguration else {
            XCTFail("Targeting configuration is not defined.")
            return
        }

        let deleteEndpointsRequest = AWSPinpointTargetingDeleteUserEndpointsRequest()!
        deleteEndpointsRequest.userId = userId
        deleteEndpointsRequest.applicationId = applicationId

        let deleteExpectation = expectation(description: "Delete endpoints")
        let lowLevelClient = lowLevelClient(from: targetingConfiguration)
        lowLevelClient.deleteUserEndpoints(deleteEndpointsRequest) { response, error in
            guard error == nil else {
                XCTFail("Unexpected error when attempting to delete endpoints")
                deleteExpectation.fulfill()
                return
            }
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1)
    }

    func testRecordEventsAreFlushed() {
        let flushEventsInvoked = expectation(description: "Flush events invoked")
        _ = Amplify.Hub.listen(to: .analytics, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                // TODO: Remove exposing AWSPinpointEvent
                guard let pinpointEvents = payload.data as? [AWSPinpointEvent] else {
                    XCTFail("Missing data")
                    flushEventsInvoked.fulfill()
                    return
                }
                XCTAssertNotNil(pinpointEvents)
                flushEventsInvoked.fulfill()
            }
        }

        let globalProperties = ["globalPropertyStringKey": "eventProperyStringValue",
                                "globalPropertyIntKey": 123,
                                "globalPropertyDoubleKey": 12.34,
                                "globalPropertyBoolKey": true] as [String: AnalyticsPropertyValue]
        Amplify.Analytics.registerGlobalProperties(globalProperties)
        let properties = ["eventPropertyStringKey": "eventProperyStringValue",
                          "eventPropertyIntKey": 123,
                          "eventPropertyDoubleKey": 12.34,
                          "eventPropertyBoolKey": true] as [String: AnalyticsPropertyValue]
        let event = BasicAnalyticsEvent(name: "eventName", properties: properties)
        Amplify.Analytics.record(event: event)
        Amplify.Analytics.flushEvents()

        wait(for: [flushEventsInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testGetEscapeHatch() throws {
        let plugin = try Amplify.Analytics.getPlugin(
            for: AWSPinpointAnalyticsPluginIntergrationTests.analyticsPluginKey)
        guard let pinpointAnalyticsPlugin = plugin as? AWSPinpointAnalyticsPlugin else {
            XCTFail("Could not get plugin of type AWSPinpointAnalyticsPlugin")
            return
        }
        let awsPinpoint = pinpointAnalyticsPlugin.getEscapeHatch()
        XCTAssertNotNil(awsPinpoint)
        XCTAssertNotNil(awsPinpoint.analyticsClient)
        XCTAssertNotNil(awsPinpoint.targetingClient)
        XCTAssertNotNil(awsPinpoint.sessionClient)
        XCTAssertNotNil(awsPinpoint.configuration)
        XCTAssertTrue(awsPinpoint.configuration.enableAutoSessionRecording)
    }

    private func escapeHatch() -> AWSPinpoint {
        guard let plugin = try? Amplify.Analytics.getPlugin(for: "awsPinpointAnalyticsPlugin"),
              let analyticsPlugin = plugin as? AWSPinpointAnalyticsPlugin else {
            fatalError("Unable to retrieve configuration")
        }
        return analyticsPlugin.getEscapeHatch()
    }

    private func lowLevelClient(from configuration: AWSServiceConfiguration) -> AWSPinpointTargeting {
        AWSPinpointTargeting.register(with: configuration, forKey: "integrationTestsTargetingConfiguration")
        return AWSPinpointTargeting.init(forKey: "integrationTestsTargetingConfiguration")
    }
}
