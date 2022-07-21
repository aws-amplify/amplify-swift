//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
@testable import AWSPinpointAnalyticsPlugin
@testable import APIHostApp
import XCTest

// swiftlint:disable:next type_name
class AWSPinpointAnalyticsPluginClientBehaviorTests: AWSPinpointAnalyticsPluginTestBase {
    let testName = "testName"
    let testIdentityId = "identityId"
    let testEmail = "testEmail"
    let testPlan = "testPlan"
    let testProperties: [String: AnalyticsPropertyValue] = ["keyString": "value",
                                                            "keyInt": 123,
                                                            "keyDouble": 1.2,
                                                            "keyBool": true]
    let testLocation = AnalyticsUserProfile.Location(latitude: 12,
                                                     longitude: 34,
                                                     postalCode: "98122",
                                                     city: "Seattle",
                                                     region: "WA",
                                                     country: "USA")

    // MARK: IdentifyUser API

    /// Given: A fully populated AnalyticsUserProfile
    /// When: AnalyticsPlugin.identifyUser is invoked with the user profile
    /// Then: AWSPinpoint.currentEndpoint and updateEndpoint methods are called
    ///     and Hub Analytics.identifyUser event is dispatched with the input data
    func testIdentifyUser() throws {
        let analyticsEventReceived = expectation(description: "Analytics event was received on the hub plugin")

        _ = plugin.listen(to: .analytics, isIncluded: nil) { payload in
            print(payload)
            if payload.eventName == HubPayload.EventName.Analytics.identifyUser {
                analyticsEventReceived.fulfill()
                guard let data = payload.data as? (String, AnalyticsUserProfile?) else {
                    XCTFail("Missing data")
                    return
                }

                XCTAssertNotNil(data)
                XCTAssertEqual(data.0, self.testIdentityId)
            }
        }

        let userProfile = AnalyticsUserProfile(name: testName,
                                               email: testEmail,
                                               plan: testPlan,
                                               location: testLocation,
                                               properties: testProperties)
        let expectedEndpointProfile = PinpointEndpointProfile(applicationId: "appId",
                                                              endpointId: "endpointId")
        expectedEndpointProfile.addIdentityId(testIdentityId)
        expectedEndpointProfile.addUserProfile(userProfile)

        analyticsPlugin.identifyUser(testIdentityId, withProfile: userProfile)

        waitForExpectations(timeout: 1)
        mockPinpoint.verifyCurrentEndpointProfile()
        mockPinpoint.verifyUpdate(expectedEndpointProfile)
    }

    /// Given: AnalyticsPlugin is disabled
    /// When: AnalyticsPlugin.identifyUser is invoked
    /// Then: AWSPinpoint.currentEndpointProfile and updateEndpointProfile methods are not called
    func testIdentifyUserDispatchesErrorForIsEnabledFalse() {
        analyticsPlugin.isEnabled = false

        analyticsPlugin.identifyUser(testIdentityId, withProfile: nil)

        XCTAssertEqual(mockPinpoint.currentEndpointProfileCalled, 0)
        XCTAssertEqual(mockPinpoint.updateEndpointProfileCalled, 0)
    }

    /// Given: An expected error from AWSPinpoint.updateEndpointProfile method call
    /// When: AnalyticsPlugin.identifyUser is invoked with the user profile
    /// Then: AWSPinpoint.currentEndpoint and updateEndpoint methods are called
    ///     and Hub Analytics.identifyUser event is dispatched with an error
    func testIdentifyUserDispatchesErrorForPinpointError() throws {
        mockPinpoint.updateEndpointProfileResult = .failure(NSError(domain: "domain",
                                                                    code: 1))
        let analyticsEventReceived = expectation(description: "Analytics event was received on the hub plugin")

        _ = plugin.listen(to: .analytics, isIncluded: nil) { payload in
            print(payload)
            if payload.eventName == HubPayload.EventName.Analytics.identifyUser {
                analyticsEventReceived.fulfill()
                guard let error = payload.data as? AnalyticsError else {
                    XCTFail("Missing error")
                    return
                }

                XCTAssertNotNil(error)
            }
        }

        let userProfile = AnalyticsUserProfile(name: testName,
                                               email: testEmail,
                                               plan: testPlan,
                                               location: testLocation,
                                               properties: testProperties)
        let expectedEndpointProfile = PinpointEndpointProfile(applicationId: "appId",
                                                              endpointId: "endpointId")
        expectedEndpointProfile.addIdentityId(testIdentityId)
        expectedEndpointProfile.addUserProfile(userProfile)

        analyticsPlugin.identifyUser(testIdentityId, withProfile: userProfile)

        waitForExpectations(timeout: 1)
        mockPinpoint.verifyCurrentEndpointProfile()
        mockPinpoint.verifyUpdate(expectedEndpointProfile)
    }

    // MARK: RecordEvent API

    /// Given: A fully populated BasicAnalyticsEvent
    /// When: AnalyticsPlugin.record is invoked with the basic event
    /// Then: AWSPinpoint.createEvent and record methods are called
    ///     and Hub Analytics.record event is dispatched with the input data
    func testRecordEvent() {
        let expectedPinpointEvent = PinpointEvent(eventType: testName, session: PinpointSession(appId: "", uniqueId: ""))
        mockPinpoint.createEventResult = expectedPinpointEvent
        expectedPinpointEvent.addProperties(testProperties)
        let event = BasicAnalyticsEvent(name: testName, properties: testProperties)

        let analyticsEventReceived = expectation(description: "Analytics event was received on the hub plugin")
        _ = plugin.listen(to: .analytics, isIncluded: nil) { payload in
            print(payload)
            if payload.eventName == HubPayload.EventName.Analytics.record {
                analyticsEventReceived.fulfill()
                guard let data = payload.data as? AnalyticsEvent else {
                    XCTFail("Missing data")
                    return
                }

                XCTAssertNotNil(data)
            }
        }

        analyticsPlugin.record(event: event)

        waitForExpectations(timeout: 1)
        mockPinpoint.verifyCreateEvent(withEventType: testName)
        mockPinpoint.verifyRecord(expectedPinpointEvent)
    }

    /// Given: AnalyticsPlugin is disabled
    /// When: AnalyticsPlugin.record is invoked
    /// Then: AWSPinpoint.record is not called
    func testRecordEventDispatchesErrorForIsEnabledFalse() {
        analyticsPlugin.isEnabled = false
        let event = BasicAnalyticsEvent(name: testName, properties: testProperties)

        analyticsPlugin.record(event: event)

        XCTAssertEqual(mockPinpoint.recordCalled, 0)
    }

    /// Given: An expected error from AWSPinpoint.record method call
    /// When: AnalyticsPlugin.record is invoked with the basic event
    /// Then: AWSPinpoint.createEvent and record methods are called
    ///     and Hub Analytics.record event is dispatched with a error
    func testRecordEventDispatchesErrorForPinpointError() {
        mockPinpoint.recordResult = .failure(NSError(domain: "domain",
                                                     code: 1,
                                                     userInfo: nil))
        let expectedPinpointEvent = PinpointEvent(eventType: testName, session: PinpointSession(appId: "", uniqueId: ""))
        mockPinpoint.createEventResult = expectedPinpointEvent
        expectedPinpointEvent.addProperties(testProperties)
        let event = BasicAnalyticsEvent(name: testName, properties: testProperties)

        let analyticsEventReceived = expectation(description: "Analytics event was received on the hub plugin")
        _ = plugin.listen(to: .analytics, isIncluded: nil) { payload in
            print(payload)
            if payload.eventName == HubPayload.EventName.Analytics.record {
                analyticsEventReceived.fulfill()
                guard let error = payload.data as? AnalyticsError else {
                    XCTFail("Missing error")
                    return
                }

                XCTAssertNotNil(error)
            }
        }

        analyticsPlugin.record(event: event)

        waitForExpectations(timeout: 1)
        mockPinpoint.verifyCreateEvent(withEventType: testName)
        mockPinpoint.verifyRecord(expectedPinpointEvent)
    }

    // MARK: RecordEventWithName API

    /// Given: An event with name
    /// When: AnalyticsPlugin.record is invoked with the event name
    /// Then: AWSPinpoint.createEvent and record methods are called
    ///     and Hub Analytics.record event is dispatched with the input data
    func testRecordEventWithName() {
        let expectedPinpointEvent = PinpointEvent(eventType: testName, session: PinpointSession(appId: "", uniqueId: ""))
        mockPinpoint.createEventResult = expectedPinpointEvent

        let analyticsEventReceived = expectation(description: "Analytics event was received on the hub plugin")
        _ = plugin.listen(to: .analytics, isIncluded: nil) { payload in
            print(payload)
            if payload.eventName == HubPayload.EventName.Analytics.record {
                analyticsEventReceived.fulfill()
                guard let data = payload.data as? AnalyticsEvent else {
                    XCTFail("Missing data")
                    return
                }

                XCTAssertNotNil(data)
            }
        }

        analyticsPlugin.record(eventWithName: testName)

        waitForExpectations(timeout: 1)
        mockPinpoint.verifyCreateEvent(withEventType: testName)
        mockPinpoint.verifyRecord(expectedPinpointEvent)
    }

    /// AnalyticsPlugin is disabled
    /// When: AnalyticsPlugin.record is invoked
    /// Then: AWSPinpoint.record is not called
    func testRecordEventWithNameDispatchesErrorForIsEnabledFalse() {
        analyticsPlugin.isEnabled = false

        analyticsPlugin.record(eventWithName: testName)

        XCTAssertEqual(mockPinpoint.recordCalled, 0)
    }

    /// Given: An expected error from AWSPinpoint.record method call
    /// When: AnalyticsPlugin.record is invoked with the event name
    /// Then: AWSPinpoint.createEvent and record methods are called
    ///     and Hub Analytics.record event is dispatched with a error
    func testRecordEventWithNameDispatchesErrorForPinpointError() {
        mockPinpoint.recordResult = .failure(NSError(domain: "domain",
                                                     code: 1,
                                                     userInfo: nil))
        let expectedPinpointEvent = PinpointEvent(eventType: testName, session: PinpointSession(appId: "", uniqueId: ""))
        mockPinpoint.createEventResult = expectedPinpointEvent

        let analyticsEventReceived = expectation(description: "Analytics event was received on the hub plugin")
        _ = plugin.listen(to: .analytics, isIncluded: nil) { payload in
            print(payload)
            if payload.eventName == HubPayload.EventName.Analytics.record {
                analyticsEventReceived.fulfill()
                guard let error = payload.data as? AnalyticsError else {
                    XCTFail("Missing error")
                    return
                }

                XCTAssertNotNil(error)
            }
        }

        analyticsPlugin.record(eventWithName: testName)

        waitForExpectations(timeout: 1)
        mockPinpoint.verifyCreateEvent(withEventType: testName)
        mockPinpoint.verifyRecord(expectedPinpointEvent)
    }

    // MARK: RegisterGlobalProperties API

    /// Given: A dictionary of properties with different AnalyticsPropertyValue subclasses
    /// When: AnalyticsPlugin.registerGlobalProperties is invoked with the properties
    /// Then: The properties are set on the AnalyticsPlugin.globalProperties
    func testRegisterGlobalProperties() {
        analyticsPlugin.registerGlobalProperties(testProperties)
        XCTAssertEqual(analyticsPlugin.globalProperties.count, testProperties.count)

        XCTAssertTrue(mockPinpoint.addGlobalMetricCalled > 0)
        XCTAssertTrue(mockPinpoint.addGlobalAttributeCalled > 0)
    }

    /// Given: An invalid property key with length greater than 50
    /// When: AnalyticsPlugin.registerGlobalProperties is invoked
    /// Then: PreconditionFailure is thrown for invalid key
    func testRegisterGlobalPropertiesWithInvalidKeys() throws {
        let keyTooLong = String(repeating: "1", count: 51)
        let properties = [keyTooLong: "value"]

        try XCTAssertThrowFatalError {
            self.analyticsPlugin.registerGlobalProperties(properties)
        }
    }

    // MARK: UnregisterGlobalProperties API

    /// Given: A dictionary of properties with different AnalyticsPropertyValue subclasses
    /// When: AnalyticsPlugin.unregisterGlobalProperties is invoked with some property keys
    /// Then: The corresponding property keys are removed from the AnalyticsPlugin.globalProperties
    func testUnregisterGlobalProperties() {
        analyticsPlugin.globalProperties = testProperties
        analyticsPlugin.unregisterGlobalProperties(Set<String>(testProperties.keys))

        XCTAssertEqual(analyticsPlugin.globalProperties.count, 0)
        XCTAssertTrue(mockPinpoint.removeGlobalMetricCalled > 0)
        XCTAssertTrue(mockPinpoint.removeGlobalAttributeCalled > 0)
    }

    /// Given: globalProperties set on the AnalyticsPlugin
    /// When: AnalyticsPlugin.unregisterGlobalProperties is invoked with no properties
    /// Then: All of the global properties are removed
    func testAllUnregisterGlobalProperties() {
        analyticsPlugin.globalProperties = testProperties

        analyticsPlugin.unregisterGlobalProperties(nil)

        XCTAssertEqual(analyticsPlugin.globalProperties.count, 0)
        XCTAssertTrue(mockPinpoint.removeGlobalMetricCalled > 0)
        XCTAssertTrue(mockPinpoint.removeGlobalAttributeCalled > 0)
    }

    // MARK: FlushEvents API

    /// When: AnalyticsPlugin.flushEvents is invoked
    /// Then: AWSPinpoint.submitEvents is invoked
    ///     and Hub Analytics.flushEvents event is dispatched with submitted events
    func testFlushEvents() {
        let result = [PinpointEvent(eventType: "1", session: PinpointSession(appId: "", uniqueId: "")),
                      PinpointEvent(eventType: "2", session: PinpointSession(appId: "", uniqueId: ""))]
        mockPinpoint.submitEventsResult = .success(result)
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")

        _ = plugin.listen(to: .analytics, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                methodWasInvokedOnPlugin.fulfill()
                guard let analyticsEvents = payload.data as? [AnalyticsEvent] else {
                    XCTFail("Missing data")
                    return
                }

                XCTAssertNotNil(analyticsEvents)
            }
        }

        analyticsPlugin.flushEvents()
        waitForExpectations(timeout: 1)
        mockPinpoint.verifySubmitEvents()
    }

    /// Given: AnalyticsPlugin is disabled
    /// When: AnalyticsPlugin.flushEvents is invoked
    /// Then: AWSPinpoint.submitEvents is not called
    func testFlushEventsDispatchesErrorForIsEnableFalse() {
        analyticsPlugin.isEnabled = false

        analyticsPlugin.flushEvents()

        XCTAssertEqual(mockPinpoint.submitEventsCalled, 0)
    }

    /// Given: An expected error from AWSPinpoint.submitEvents method call
    /// When: AnalyticsPlugin.flushEvents is invoked
    /// Then: AWSPinpoint.submitEvents is invoked
    ///     and Hub Analytics.flushEvents event is dispatched with error
    func testFlushEventsDispatchesErrorForPinpointError() {
        mockPinpoint.submitEventsResult = .failure(NSError(domain: "domain",
                                                           code: 1,
                                                           userInfo: nil))
        let methodWasInvokedOnPlugin = expectation(description: "method was invoked on plugin")

        _ = plugin.listen(to: .analytics, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                methodWasInvokedOnPlugin.fulfill()
                guard let error = payload.data as? AnalyticsError else {
                    XCTFail("Missing error")
                    return
                }

                XCTAssertNotNil(error)
            }
        }

        analyticsPlugin.flushEvents()
        waitForExpectations(timeout: 1)
        mockPinpoint.verifySubmitEvents()
    }

    // MARK: Enable API

    func testEnable() {
        analyticsPlugin.enable()
        XCTAssertTrue(analyticsPlugin.isEnabled)
    }

    // MARK: Disable API

    func testDisable() {
        analyticsPlugin.disable()
        XCTAssertFalse(analyticsPlugin.isEnabled)
    }
}
