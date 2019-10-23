//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

// TODO: These tests are not complete, just testing test base's set up and tear down cycles
class AWSPinpointAnalyticsPluginIntegrationTests: AWSPinpointAnalyticsPluginTestBase {

    func testIdentifyUser() {
        Amplify.Analytics.identifyUser("testIdentityId")
    }

    func testRecord() {
        Amplify.Analytics.record(eventWithName: "name")
    }

    func testRegisterGlobalProperties() {
        let properties = ["key": "value"]
        Amplify.Analytics.registerGlobalProperties(properties)
    }

    func testUnregisterGlobalProperties() {
        Amplify.Analytics.unregisterGlobalProperties(["key"])
    }

    func testFlushEvents() {
        Amplify.Analytics.flushEvents()
    }

    func testEnable() {
        Amplify.Analytics.enable()
    }

    func testDisable() {
        Amplify.Analytics.disable()
    }
}
