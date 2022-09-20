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

// swiftlint:disable:next type_name
class AWSPinpointAnalyticsPluginIntergrationTests: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/AWSPinpointAnalyticsPluginIntegrationTests-amplifyconfiguration"
    static let analyticsPluginKey = "awsPinpointAnalyticsPlugin"

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

    func testIdentifyUser() async throws {
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
        Amplify.Analytics.identifyUser(userId: userId, userProfile: userProfile)

        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        // Remove userId from the current endpoint
        let endpointClient = endpointClient()
        let currentProfile = await endpointClient.currentEndpointProfile()
        currentProfile.addUserId("")
        try await endpointClient.updateEndpointProfile(with: currentProfile)
    }

    /// Run this test when the number of endpoints for the userId exceeds the limit.
    /// The profile should have permissions to run the "mobiletargeting:DeleteUserEndpoints" action.
    func skip_testDeleteEndpointsForUser() async throws {
        let userId = "userId"
        let applicationId = await endpointClient().currentEndpointProfile().applicationId
        let deleteEndpointsRequest = DeleteUserEndpointsInput(applicationId: applicationId,
                                                              userId: userId)
        do {
            let response = try await pinpointClient().deleteUserEndpoints(input: deleteEndpointsRequest)
            XCTAssertNotNil(response.endpointsResponse)
        } catch {
            XCTFail("Unexpected error when attempting to delete endpoints")
        }
    }

    func testRecordEventsAreFlushed() {
        let flushEventsInvoked = expectation(description: "Flush events invoked")
        _ = Amplify.Hub.listen(to: .analytics, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                // TODO: Remove exposing AWSPinpointEvent
                guard let pinpointEvents = payload.data as? [AnalyticsEvent] else {
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
    }

    private func plugin() -> AWSPinpointAnalyticsPlugin {
        guard let plugin = try? Amplify.Analytics.getPlugin(for: "awsPinpointAnalyticsPlugin"),
              let analyticsPlugin = plugin as? AWSPinpointAnalyticsPlugin else {
            fatalError("Unable to retrieve configuration")
        }

        return analyticsPlugin
    }

    private func pinpointClient() -> PinpointClientProtocol {
        return plugin().getEscapeHatch()
    }

    private func endpointClient() -> EndpointClientBehaviour {
        guard let context = plugin().pinpoint as? PinpointContext else {
            fatalError("Unable to retrieve Pinpoint Context")
        }
        return context.endpointClient
    }
}
