//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPinpoint

@testable import Amplify
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
@testable import AWSPinpointAnalyticsPlugin
import AWSCognitoAuthPlugin
import Network

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

    /// Given: Analytics plugin
    /// When: identifyUser api is called
    /// Then: IdentifyUser Hub event is received
    func skip_testIdentifyUser() async throws {
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

    /// Given: Analytics plugin
    /// When: An analytics event is recorded and flushed
    /// Then: Flush Hub event is received
    func testRecordEventsAreFlushed() {
        let onlineExpectation = expectation(description: "Device is online")
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { newPath in
            if newPath.status == .satisfied {
                onlineExpectation.fulfill()
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "AWSPinpointAnalyticsPluginIntergrationTests.NetworkMonitor"))
        
        let flushEventsInvoked = expectation(description: "Flush events invoked")
        _ = Amplify.Hub.listen(to: .analytics, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                guard let pinpointEvents = payload.data as? [AnalyticsEvent] else {
                    XCTFail("Missing data")
                    flushEventsInvoked.fulfill()
                    return
                }
                XCTAssertFalse(pinpointEvents.isEmpty)
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
       
        wait(for: [onlineExpectation], timeout: TestCommonConstants.networkTimeout)

        Amplify.Analytics.flushEvents()

        wait(for: [flushEventsInvoked], timeout: TestCommonConstants.networkTimeout)
    }
    
    /// Given: Analytics plugin
    /// When: An analytics event is recorded and flushed after the plugin is enabled
    /// Then: Flush Hub event is received
    func testRecordsAreFlushedWhenPluginEnabled() {
        let onlineExpectation = expectation(description: "Device is online")
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { newPath in
            if newPath.status == .satisfied {
                onlineExpectation.fulfill()
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "AWSPinpointAnalyticsPluginIntergrationTests.NetworkMonitor"))
        
        let flushEventsInvoked = expectation(description: "Flush events invoked")
        _ = Amplify.Hub.listen(to: .analytics, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                guard let pinpointEvents = payload.data as? [AnalyticsEvent] else {
                    XCTFail("Missing data")
                    flushEventsInvoked.fulfill()
                    return
                }
                XCTAssertFalse(pinpointEvents.isEmpty)
                flushEventsInvoked.fulfill()
            }
        }
        
        Amplify.Analytics.disable()
        Amplify.Analytics.enable()

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
       
        wait(for: [onlineExpectation], timeout: TestCommonConstants.networkTimeout)

        Amplify.Analytics.flushEvents()

        wait(for: [flushEventsInvoked], timeout: TestCommonConstants.networkTimeout)
    }
    
    /// Given: Analytics plugin
    /// When: An analytics event is recorded and flushed after the plugin is disabled
    /// Then: Flush Hub event is not received
    func testRecordsAreNotFlushedWhenPluginDisabled() {
        let onlineExpectation = expectation(description: "Device is online")
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { newPath in
            if newPath.status == .satisfied {
                onlineExpectation.fulfill()
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "AWSPinpointAnalyticsPluginIntergrationTests.NetworkMonitor"))
        
        let flushEventsInvoked = expectation(description: "Flush events invoked")
        _ = Amplify.Hub.listen(to: .analytics, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                flushEventsInvoked.fulfill()
            }
        }
        flushEventsInvoked.isInverted = true
        
        Amplify.Analytics.disable()
        
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
       
        wait(for: [onlineExpectation], timeout: TestCommonConstants.networkTimeout)

        Amplify.Analytics.flushEvents()
        wait(for: [flushEventsInvoked], timeout: TestCommonConstants.networkTimeout)
    }
    
    /// Given: Analytics plugin
    /// When: An analytics event is recorded and flushed with global properties registered
    /// Then: Flush Hub event is received with global properties
    func testRegisterGlobalProperties() {
        let onlineExpectation = expectation(description: "Device is online")
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { newPath in
            if newPath.status == .satisfied {
                onlineExpectation.fulfill()
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "AWSPinpointAnalyticsPluginIntergrationTests.NetworkMonitor"))
        
        let flushEventsInvoked = expectation(description: "Flush events invoked")
        _ = Amplify.Hub.listen(to: .analytics, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                guard let pinpointEvents = payload.data as? [AnalyticsEvent] else {
                    XCTFail("Missing data")
                    flushEventsInvoked.fulfill()
                    return
                }
                XCTAssertFalse(pinpointEvents.isEmpty)
                guard let event = pinpointEvents.first else {
                    XCTFail("Missing data")
                    flushEventsInvoked.fulfill()
                    return
                }
                XCTAssertTrue(event.properties?.keys.contains("globalPropertyStringKey") == true)
                XCTAssertTrue(event.properties?.keys.contains("globalPropertyIntKey") == true)
                XCTAssertTrue(event.properties?.keys.contains("globalPropertyDoubleKey") == true)
                XCTAssertTrue(event.properties?.keys.contains("globalPropertyBoolKey") == true)
                flushEventsInvoked.fulfill()
            }
        }
        
        let globalProperties = ["globalPropertyStringKey": "GlobalProperyStringValue",
                                "globalPropertyIntKey": 321,
                                "globalPropertyDoubleKey": 43.21,
                                "globalPropertyBoolKey": true] as [String: AnalyticsPropertyValue]
        Amplify.Analytics.registerGlobalProperties(globalProperties)
        let properties = ["eventPropertyStringKey": "eventProperyStringValue",
                          "eventPropertyIntKey": 123,
                          "eventPropertyDoubleKey": 12.34,
                          "eventPropertyBoolKey": true] as [String: AnalyticsPropertyValue]
        let event = BasicAnalyticsEvent(name: "eventName", properties: properties)
        Amplify.Analytics.record(event: event)
       
        wait(for: [onlineExpectation], timeout: TestCommonConstants.networkTimeout)

        Amplify.Analytics.flushEvents()
        wait(for: [flushEventsInvoked], timeout: TestCommonConstants.networkTimeout)
    }
    
    /// Given: Analytics plugin
    /// When: An analytics event is recorded and flushed with global properties registered
    /// Then: Flush Hub event is received without global properties
    func testUnRegisterGlobalProperties() {
        let onlineExpectation = expectation(description: "Device is online")
        let networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { newPath in
            if newPath.status == .satisfied {
                onlineExpectation.fulfill()
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "AWSPinpointAnalyticsPluginIntergrationTests.NetworkMonitor"))
        
        let flushEventsInvoked = expectation(description: "Flush events invoked")
        _ = Amplify.Hub.listen(to: .analytics, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                guard let pinpointEvents = payload.data as? [AnalyticsEvent] else {
                    XCTFail("Missing data")
                    flushEventsInvoked.fulfill()
                    return
                }
                XCTAssertFalse(pinpointEvents.isEmpty)
                guard let event = pinpointEvents.first else {
                    XCTFail("Missing data")
                    flushEventsInvoked.fulfill()
                    return
                }
                XCTAssertFalse(event.properties?.keys.contains("globalPropertyStringKey") == true)
                XCTAssertFalse(event.properties?.keys.contains("globalPropertyIntKey") == true)
                XCTAssertFalse(event.properties?.keys.contains("globalPropertyDoubleKey") == true)
                XCTAssertFalse(event.properties?.keys.contains("globalPropertyBoolKey") == true)
                flushEventsInvoked.fulfill()
            }
        }
        
        let globalProperties = ["globalPropertyStringKey": "GlobalProperyStringValue",
                                "globalPropertyIntKey": 321,
                                "globalPropertyDoubleKey": 43.21,
                                "globalPropertyBoolKey": true] as [String: AnalyticsPropertyValue]
        Amplify.Analytics.registerGlobalProperties(globalProperties)
        Amplify.Analytics.unregisterGlobalProperties()
        let properties = ["eventPropertyStringKey": "eventProperyStringValue",
                          "eventPropertyIntKey": 123,
                          "eventPropertyDoubleKey": 12.34,
                          "eventPropertyBoolKey": true] as [String: AnalyticsPropertyValue]
        let event = BasicAnalyticsEvent(name: "eventName", properties: properties)
        Amplify.Analytics.record(event: event)
       
        wait(for: [onlineExpectation], timeout: TestCommonConstants.networkTimeout)

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
