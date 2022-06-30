//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSPinpointAnalyticsPlugin

class AWSPinpointAnalyticsNotificationsTests: XCTestCase {
    var pinpointNotifications: AWSPinpointAnalyticsNotifications!
    var analyticsClient = MockAnalyticsClient()
    var targetingClient = MockAWSPinpoint()
    var userDefaults = MockUserDefaults()

    override  func setUpWithError() throws {
        pinpointNotifications = AWSPinpointAnalyticsNotifications(analyticsClient: analyticsClient,
                                                              targetingClient: targetingClient,
                                                              userDefaults: userDefaults)
    }
    
    func testAddPinpointMetadataForEventCampaign() {
        guard let event = PinpointEvent.makeEvent(eventSource: .campaign,
                                                  pushAction: .receivedForeground,
                                                  usingClient: analyticsClient) else {
            XCTFail("Failed creating Pinpoint event")
            return
        }
        
        event.addSourceMetadata(TestData.campaignMetadata)
        XCTAssertEqual(event.attributes[TestData.campaignAttributeKey], TestData.campaignAttributeValue)
    }
    
    func testMakePinpintPushActionFromEvent() {
        let pushActions = [
            // Check that when the application is in an active state
            // the push event is used to return the appropriate push action
            pinpointNotifications.makePinpointPushAction(fromEvent: .opened, appState: .active),
            pinpointNotifications.makePinpointPushAction(fromEvent: .received, appState: .active),
            
            
            pinpointNotifications.makePinpointPushAction(fromEvent: .opened, appState: .inactive),
            pinpointNotifications.makePinpointPushAction(fromEvent: .received, appState: .inactive),
            pinpointNotifications.makePinpointPushAction(fromEvent: .opened, appState: .background),
            pinpointNotifications.makePinpointPushAction(fromEvent: .received, appState: .background),
            
        ]
        
        let expectedPushActions: [AWSPinpointPushAction] = [
            .openedNotification,
            .receivedForeground,
            .openedNotification,
            .openedNotification,
            .receivedBackground,
            .receivedBackground
        ]
        
        XCTAssertEqual(pushActions, expectedPushActions)
    }
    
    func testHandleDeepLink() {
        let expectedURL = URL(string: "https://deeplink.amplify.aws")
        var deepLinkURL: URL?
        let mockCanOpenURL: AWSPinpointAnalyticsNotifications.CanOpenURL = { url in
            deepLinkURL = url
            return false
        }
        let userInfo: AWSPinpointAnalyticsNotifications.UserInfo = [
            PinpointContext.Constants.Notifications.dataKey: [
                PinpointContext.Constants.Notifications.pinpointKey: [
                    PinpointContext.Constants.Notifications.deeplinkKey: expectedURL!.absoluteString]
            ]
        ]
        pinpointNotifications.handleDeepLinkForNotification(userInfo: userInfo,
                                                            canOpenURL: mockCanOpenURL)
        XCTAssertEqual(deepLinkURL, expectedURL)
    }
    
    
    func testPinpointEventMakeFromValidEventSource() {
        let eventSource = AWSPinpointAnalyticsNotifications.EventSource.campaign
        let pushAction = AWSPinpointPushAction.openedNotification
        let event = PinpointEvent.makeEvent(eventSource: eventSource,
                                            pushAction: pushAction,
                                            usingClient: analyticsClient)
        XCTAssertEqual(event?.eventType, "_\(eventSource.rawValue).\(pushAction.rawValue)")
    }
    
    func testPinpointEventMakeFromUnknownPushEvent() {
        let event = PinpointEvent.makeEvent(eventSource: .campaign,
                                            pushAction: .unknown,
                                            usingClient: analyticsClient)
        XCTAssertNil(event)
    }
    
    // MARK: public APIs tests
    func testInterceptDidFinishLaunchingWithOptions() async {
        let payload = [UIApplication.LaunchOptionsKey.remoteNotification: TestData.campaignPushPayload]
        _ = await pinpointNotifications.interceptDidFinishLaunchingWithOptions(launchOptions: payload)
        
        let recordedEvent = await analyticsClient.lastRecordedEvent
        XCTAssertNotNil(recordedEvent)
        
        let (expectedAttributeKey, expectedAttributeValue) = await analyticsClient.addGlobalAttributeCalls[0]
        XCTAssertEqual(expectedAttributeKey,TestData.campaignAttributeKey)
        XCTAssertEqual(expectedAttributeValue,TestData.campaignAttributeValue)
        
    }
    
    func testInterceptDidRegisterForRemoteNotificationsWithDeviceToken() async {
        let deviceToken = Data()
        await pinpointNotifications.interceptDidRegisterForRemoteNotificationsWithDeviceToken(deviceToken: deviceToken)
        
        XCTAssertEqual(userDefaults.dataForKeyCountMap[EndpointClient.Constants.deviceTokenKey], 1)
        
        XCTAssertEqual(userDefaults.data[EndpointClient.Constants.deviceTokenKey] as? Data, deviceToken)
        
        targetingClient.verifyUpdateEndpointProfile()
    }
}


// MARK: - Test data
extension AWSPinpointAnalyticsNotificationsTests {
    struct TestData {
        static let campaignAttributeKey = "campaign_id"
        static let journeyAttributeKey = "journey_id"
        static let campaignAttributeValue = "testCampaignId"
        static let journeyAttributeValue = "testJourneyId"
        
        static var campaignMetadata = [
            campaignAttributeKey: campaignAttributeValue
        ]
        
        static let journeyMetadata = [
            journeyAttributeKey: journeyAttributeValue
        ]
        
        static let campaignPushPayload = [
            "data": [
                "pinpoint": ["campaign": campaignMetadata]
            ]
        ]
    }
}
