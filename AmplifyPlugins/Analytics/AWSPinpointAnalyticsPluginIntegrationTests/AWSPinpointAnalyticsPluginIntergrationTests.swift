//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSPinpointAnalyticsPlugin
import AWSMobileClient
import AWSPinpoint

class AWSPinpointAnalyticsPluginIntergrationTests: XCTestCase {

    /*
     Set up
     `amplify init`
     `amplify add analytics`
       * Apps need authorization to send analytics events. Do you want to allow guests and unauthenticated users to send
         analytics events? (we recommend you allow this when getting started) `Yes`
     `amplify push`

     Pinpoint URL to track events
     https://us-west-2.console.aws.amazon.com/pinpoint/home/?region=us-west-2#/apps/xxx/analytics/overview

     awsconfiguration.json
     {
         "UserAgent": "aws-amplify/cli",
         "Version": "0.1.0",
         "IdentityManager": {
             "Default": {}
         },
         "CredentialsProvider": {
             "CognitoIdentity": {
                 "Default": {
                     "PoolId": "us-west-2:xxx",
                     "Region": "us-west-2"
                 }
             }
         },
         "PinpointAnalytics": {
             "Default": {
                 "AppId": "xxx",
                 "Region": "us-west-2"
             }
         },
         "PinpointTargeting": {
             "Default": {
                 "Region": "us-west-2"
             }
         }
     }

     amplifyconfiguration.json
     {
         "UserAgent": "aws-amplify-cli/2.0",
         "Version": "1.0",
         "analytics": {
             "plugins": {
                 "awsPinpointAnalyticsPlugin": {
                     "pinpointAnalytics": {
                         "appId": "xxxx",
                         "region": "us-west-2"
                     },
                     "pinpointTargeting": {
                         "region": "us-west-2"
                     }
                 }
             }
         }
     }
     */
    let analyticsPluginKey = "awsPinpointAnalyticsPlugin"

    override func setUp() {
        let config = [
            "CredentialsProvider": [
                "CognitoIdentity": [
                    "Default": [
                        "PoolId": "us-west-2:xxx",
                        "Region": "us-west-2"
                    ]
                ]
            ]
        ]
        AWSInfo.configureDefaultAWSInfo(config)

        let mobileClientIsInitialized = expectation(description: "AWSMobileClient is initialized")
        AWSMobileClient.default().initialize { userState, error in
            guard error == nil else {
                XCTFail("Error initializing AWSMobileClient. Error: \(error!.localizedDescription)")
                return
            }
            guard let userState = userState else {
                XCTFail("userState is unexpectedly empty initializing AWSMobileClient")
                return
            }
            if userState != UserState.signedOut {
                AWSMobileClient.default().signOut()
            }
            mobileClientIsInitialized.fulfill()
        }
        wait(for: [mobileClientIsInitialized], timeout: 100)
        print("AWSMobileClient Initialized")

        let analyticsConfig = AnalyticsCategoryConfiguration(
            plugins: [
                "awsPinpointAnalyticsPlugin": [
                    "pinpointAnalytics": [
                        "appId": "xxxxx",
                        "region": "us-west-2"
                    ],
                    "pinpointTargeting": [
                        "region": "us-west-2"
                    ],
                    "autoFlushEventsInterval": 10,
                    "trackAppSessions": true,
                    "autoSessionTrackingInterval": 2
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(analytics: analyticsConfig)

        do {
            try Amplify.add(plugin: AWSPinpointAnalyticsPlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify")
        }

        print("Amplify initialized")
    }

    override func tearDown() {
        print("Amplify reset")
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

        wait(for: [identifyUserEvent], timeout: 20)
    }

    func testRecordEventsAreFlushed() {
        let flushEventsInvoked = expectation(description: "Flush events invoked")
        _ = Amplify.Hub.listen(to: .analytics, isIncluded: nil) { payload in
            if payload.eventName == HubPayload.EventName.Analytics.flushEvents {
                // TODO: Remove exposing AWSPinpointEvent
                guard let pinpointEvents = payload.data as? [AWSPinpointEvent] else {
                    XCTFail("Missing data")
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

        wait(for: [flushEventsInvoked], timeout: 20)
    }

    func testGetEscapeHatch() throws {
        let plugin = try Amplify.Analytics.getPlugin(for: analyticsPluginKey)
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
}
