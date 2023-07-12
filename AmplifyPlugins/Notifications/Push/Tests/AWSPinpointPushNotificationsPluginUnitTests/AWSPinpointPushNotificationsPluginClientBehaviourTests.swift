//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
@testable import AWSPinpointPushNotificationsPlugin
import UserNotifications
import XCTest

class AWSPinpointPushNotificationsPluginClientBehaviourTests: AWSPinpointPushNotificationsPluginTestBase {
    override func setUp() async throws {
        try await super.setUp()
        plugin.configure(pinpoint: mockPinpoint,
                         remoteNotificationsHelper: mockRemoteNotifications)
    }
    
    // MARK: - Identify User tests
    func testIdentifyUser_shouldUpdateUserId() async throws {
        try await plugin.identifyUser(userId: "newUserId", userProfile: nil)
        
        XCTAssertEqual(mockPinpoint.currentEndpointProfileCount, 1)
        XCTAssertEqual(mockPinpoint.updateEndpointCount, 1)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.user.userId, "newUserId")
    }

    func testIdentifyUser_withProfile_shouldUpdateUserProfile() async throws {
        let userProfile = BasicUserProfile(
            name: "Name",
            email: "Email",
            plan: "Plan"
        )
        try await plugin.identifyUser(userId: "newUserId", userProfile: userProfile)

        XCTAssertEqual(mockPinpoint.currentEndpointProfileCount, 1)
        XCTAssertEqual(mockPinpoint.updateEndpointCount, 1)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.user.userId, "newUserId")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes.count, 3)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["name"]?.first, "Name")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["email"]?.first, "Email")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["plan"]?.first, "Plan")
        XCTAssertTrue(mockPinpoint.mockedPinpointEndpointProfile.metrics.isEmpty)
        XCTAssertNil(mockPinpoint.mockedPinpointEndpointProfile.user.userAttributes)
    }

    func testIdentifyUser_withAnalyticsProfile_shouldUpdateUserProfile() async throws {
        let analyticsProfile = AnalyticsUserProfile(
            properties: [
                "attribute": "string",
                "metric": 2.0,
                "boolAttribute": true,
                "intMetric": 1,
            ]
        )
        try await plugin.identifyUser(userId: "newUserId", userProfile: analyticsProfile)

        XCTAssertEqual(mockPinpoint.currentEndpointProfileCount, 1)
        XCTAssertEqual(mockPinpoint.updateEndpointCount, 1)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.user.userId, "newUserId")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes.count, 2)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["attribute"]?.first, "string")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["boolAttribute"]?.first, "true")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.metrics["metric"], 2.0)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.metrics["intMetric"], 1)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.metrics.count, 2)
        XCTAssertNil(mockPinpoint.mockedPinpointEndpointProfile.user.userAttributes)
    }

    func testIdentifyUser_withBasicProfile_shouldUpdateUserProfile() async throws {
        let basicUserProfile = BasicUserProfile(
            customProperties: [
                "attribute": "string",
                "metric": 2.0,
                "boolAttribute": true,
                "intMetric": 1,
            ]
        )
        try await plugin.identifyUser(userId: "newUserId", userProfile: basicUserProfile)

        XCTAssertEqual(mockPinpoint.currentEndpointProfileCount, 1)
        XCTAssertEqual(mockPinpoint.updateEndpointCount, 1)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.user.userId, "newUserId")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes.count, 2)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["attribute"]?.first, "string")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["boolAttribute"]?.first, "true")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.metrics["metric"], 2.0)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.metrics["intMetric"], 1)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.metrics.count, 2)
        XCTAssertNil(mockPinpoint.mockedPinpointEndpointProfile.user.userAttributes)
    }

    func testIdentifyUser_withPinpointProfile_shouldUpdateUserProfile() async throws {
        let pinpointUserProfile = PinpointUserProfile(
            customProperties: [
                "attribute": "string",
                "attributes": ["string", "anotherString"],
                "boolAttribute": true,
                "metric": 2.0,
                "intMetric": 1,
            ],
            userAttributes: [
                "roles": ["Test", "Validator"]
            ]
        )
        try await plugin.identifyUser(userId: "newUserId", userProfile: pinpointUserProfile)

        XCTAssertEqual(mockPinpoint.currentEndpointProfileCount, 1)
        XCTAssertEqual(mockPinpoint.updateEndpointCount, 1)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["attribute"]?.first, "string")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["attributes"]?.count, 2)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["attributes"]?.first, "string")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.attributes["boolAttribute"]?.first, "true")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.metrics["metric"], 2)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.metrics["intMetric"], 1)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.user.userId, "newUserId")
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.user.userAttributes?["roles"]?.count, 2)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.user.userAttributes?["roles"]?.first, "Test")
    }

    func testIdentifyUser_withPinpointProfileOptedOutOfMessages_shouldUpdateUserProfileOptOutValue() async throws {
        try await plugin.identifyUser(userId: "newUserId", userProfile: nil)
        let updatedEndpoint = try XCTUnwrap(mockPinpoint.updatedPinpointEndpointProfile)
        XCTAssertFalse(updatedEndpoint.isOptOut)

        try await plugin.identifyUser(userId: "newUserId", userProfile: PinpointUserProfile(optedOutOfMessages: true))
        XCTAssertTrue(updatedEndpoint.isOptOut)

        try await plugin.identifyUser(userId: "newUserId", userProfile: PinpointUserProfile(name: "User"))
        XCTAssertTrue(updatedEndpoint.isOptOut)
    }
    
    // MARK: - Register Device tests
    func testRegisterDevice_shouldUpdateDeviceToken() async throws {
        let apnsToken = "apnsToken".data(using: .utf8)!
        try await plugin.registerDevice(apnsToken: apnsToken)
        
        XCTAssertEqual(mockPinpoint.currentEndpointProfileCount, 1)
        XCTAssertEqual(mockPinpoint.updateEndpointCount, 1)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.deviceToken, apnsToken.asHexString())
    }
    
    // MARK: - Record Notification received tests
    func testRecordNotificationReceived_withValidCampaignPayload_shouldRecordEvent() async throws {
        try await plugin.recordNotificationReceived(createUserInfo(for: .campaign))
        
        XCTAssertEqual(mockPinpoint.createEventCount, 1)
        XCTAssertTrue(mockPinpoint.mockedCreatedEvent!.eventType.starts(with: "_campaign.received_"))
        XCTAssertEqual(mockPinpoint.setRemoteGlobalAttributesCount, 1)
        XCTAssertEqual(mockPinpoint.recordCount, 1)
    }
    
    func testRecordNotificationReceived_withValidJourneyPayload_shouldRecordEvent() async throws {
        try await plugin.recordNotificationReceived(createUserInfo(for: .journey))
        
        XCTAssertEqual(mockPinpoint.createEventCount, 1)
        XCTAssertTrue(mockPinpoint.mockedCreatedEvent!.eventType.starts(with: "_journey.received_"))
        XCTAssertEqual(mockPinpoint.setRemoteGlobalAttributesCount, 1)
        XCTAssertEqual(mockPinpoint.recordCount, 1)
    }
    
    func testRecordNotificationReceived_withInvalidPayload_shouldRecordEvent() async throws {
        let userInfo: Notifications.Push.UserInfo = [
            "invalid": "payload"
        ]
        try await plugin.recordNotificationReceived(userInfo)
        
        XCTAssertEqual(mockPinpoint.createEventCount, 0)
        XCTAssertNil(mockPinpoint.mockedCreatedEvent?.eventType)
        XCTAssertEqual(mockPinpoint.setRemoteGlobalAttributesCount, 0)
        XCTAssertEqual(mockPinpoint.recordCount, 0)
    }
    
    // MARK: - Record Notification opened tests
#if !os(tvOS)
    func testRecordNotificationOpened_withValidCampaignPayload_shouldRecordEvent() async throws {
        let response = UNNotificationResponse(coder: createCoder(for: .campaign))!
        try await plugin.recordNotificationOpened(response)
        
        XCTAssertEqual(mockPinpoint.createEventCount, 1)
        XCTAssertEqual(mockPinpoint.mockedCreatedEvent?.eventType, "_campaign.opened_notification")
        XCTAssertEqual(mockPinpoint.setRemoteGlobalAttributesCount, 1)
        XCTAssertEqual(mockPinpoint.recordCount, 1)
    }
    
    func testRecordNotificationOpened_withValidJourneyPayload_shouldRecordEvent() async throws {
        let response = UNNotificationResponse(coder: createCoder(for: .journey))!
        try await plugin.recordNotificationOpened(response)
        
        XCTAssertEqual(mockPinpoint.createEventCount, 1)
        XCTAssertEqual(mockPinpoint.mockedCreatedEvent?.eventType, "_journey.opened_notification")
        XCTAssertEqual(mockPinpoint.setRemoteGlobalAttributesCount, 1)
        XCTAssertEqual(mockPinpoint.recordCount, 1)
    }
    
    func testRecordNotificationOpened_withInvalidPayload_shouldRecordEvent() async throws {
        let response = UNNotificationResponse(coder: MockedKeyedArchiver(requiringSecureCoding: false))!
        try await plugin.recordNotificationOpened(response)
        
        XCTAssertEqual(mockPinpoint.createEventCount, 0)
        XCTAssertNil(mockPinpoint.mockedCreatedEvent?.eventType)
        XCTAssertEqual(mockPinpoint.setRemoteGlobalAttributesCount, 0)
        XCTAssertEqual(mockPinpoint.recordCount, 0)
    }
#endif
    
    private func createUserInfo(for source: PushNotification.Source) -> Notifications.Push.UserInfo {
        return [
            "data": [
                "pinpoint": [
                    "\(source.rawValue)": [
                        "attribute": "value"
                    ]
                ]
            ]
        ]
    }
    
    private func createCoder(for source: PushNotification.Source) -> NSKeyedArchiver {
        let archiver = MockedKeyedArchiver(requiringSecureCoding: false)
        archiver.userInfo = createUserInfo(for: source)
        return archiver
    }
    
    private class MockedKeyedArchiver: NSKeyedArchiver {
        var userInfo: Notifications.Push.UserInfo = [:]
        
        override func decodeObject(forKey key: String) -> Any {
            switch key {
            case "notification":
                return UNNotification(coder: self) as Any
            case "request":
                return UNNotificationRequest(identifier: "identifier",
                                             content: UNNotificationContent(coder: self)!,
                                             trigger: nil)
            case "userInfo":
                return userInfo
            default:
                return ""
            }
        }
        
        override func decodeInt64(forKey _: String) -> Int64 { 0 }
        override func decodeBool(forKey _: String) -> Bool { true }
        override func containsValue(forKey _: String) -> Bool { false }
        override func decodeFloat(forKey _: String) -> Float { 0.0 }
    }
}
