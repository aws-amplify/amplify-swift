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
        try await plugin.identifyUser(userId: "newUserId")
        
        XCTAssertEqual(mockPinpoint.currentEndpointProfileCount, 1)
        XCTAssertEqual(mockPinpoint.updateEndpointCount, 1)
        XCTAssertEqual(mockPinpoint.mockedPinpointEndpointProfile.user.userId, "newUserId")
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
