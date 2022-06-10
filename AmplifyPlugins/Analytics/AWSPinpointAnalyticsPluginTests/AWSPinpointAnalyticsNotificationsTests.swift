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
    var pinpointAnalytics: AWSPinpointAnalyticsNotifications!
    var context: PinpointContext!

    override  func setUpWithError() throws {
        context = try PinpointContext(with: PinpointContextConfiguration(appId: "appId"),
                                      credentialsProvider: MockAWSAuthService().getCredentialsProvider(),
                                      region: "region")
        pinpointAnalytics = AWSPinpointAnalyticsNotifications(context: context)
    }
    
    func testAddPinpointMetadataForEventCampaign() {
        guard let event = PinpointEvent.makeEvent(eventSource: .campaign,
                                                  pushAction: .receivedForeground,
                                                  usingClient: context.analyticsClient) else {
            XCTFail("Failed creating Pinpoint event")
            return
        }
        
        event.addSourceMetadata(TestData.campaignMetadata)
        
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
