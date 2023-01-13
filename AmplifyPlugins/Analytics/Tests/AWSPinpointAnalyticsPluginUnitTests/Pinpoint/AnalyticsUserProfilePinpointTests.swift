//
//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpointAnalyticsPlugin
import XCTest

class AnalyticsUserProfilePinpointTests: XCTestCase {

    /// Given: A AnalyticsUserProfile
    /// When: AnalyticsUserProfile.addPinpointEndpointCustomProperty(forKey) is invoked with a key and value
    /// Then: The key is prefixed with a custom attribute prefix
    ///      and the pair is included in AnalyticsUserProfile.endpointCustomProperties
    ///      and the pair is not included in AnalyticsUserProfile.endpointUserProperties
    func testAddPinpointEndpointCustomProperty_shouldAddPrefix() {
        var userProfile = AnalyticsUserProfile()
        userProfile.addPinpointEndpointCustomProperty("value", forKey: "key")

        guard let properties = userProfile.properties else {
            XCTFail("Properties should not be nil")
            return
        }

        XCTAssertNil(properties["key"])
        XCTAssertNotNil(properties["\(AnalyticsUserProfile.AWSPinpoint.Endpoint.customAttributePrefix)key"])
        XCTAssertEqual(userProfile.endpointCustomProperties?.count, 1)
        XCTAssertTrue(userProfile.endpointUserProperties?.isEmpty ?? false)
    }

    /// Given: A AnalyticsUserProfile
    /// When: AnalyticsUserProfile.addPinpointEndpointProperties() is invoked with a dictionary containg pairs of keys and values
    /// Then: Each key is prefixed with a custom attribute prefix
    ///      and each pair is included in AnalyticsUserProfile.endpointCustomProperties
    ///      and each pair is not included in AnalyticsUserProfile.endpointUserProperties
    func testAddPinpointEndpointCustomProperties_shouldAddPrefixes() {
        var userProfile = AnalyticsUserProfile()
        let endpointProperties: AnalyticsProperties = [
            "attributeKey": "string",
            "metricKey": 2
        ]
        userProfile.addPinpointEndpointProperties(endpointProperties)

        guard let properties = userProfile.properties else {
            XCTFail("Properties should not be nil")
            return
        }

        XCTAssertNil(properties["attributeKey"])
        XCTAssertNil(properties["metricKey"])
        XCTAssertNotNil(properties["\(AnalyticsUserProfile.AWSPinpoint.Endpoint.customAttributePrefix)attributeKey"])
        XCTAssertNotNil(properties["\(AnalyticsUserProfile.AWSPinpoint.Endpoint.customAttributePrefix)metricKey"])
        XCTAssertEqual(userProfile.endpointCustomProperties?.count, endpointProperties.count)
        XCTAssertTrue(userProfile.endpointUserProperties?.isEmpty ?? false)
    }

    /// Given: A AnalyticsUserProfile
    /// When: AnalyticsUserProfile.addPinpointEndpointUserProperty(forKey) is invoked with a key and value
    /// Then: The key is prefixed with a custom attribute prefix
    ///      and the pair is included in AnalyticsUserProfile.endpointUserProperties
    ///      and the pair is not included in AnalyticsUserProfile.endpointCustomProperties
    func testAddPinpointEndpointUserProperty_shouldAddPrefix() {
        var userProfile = AnalyticsUserProfile()
        userProfile.addPinpointEndpointUserProperty("value", forKey: "key")

        guard let properties = userProfile.properties else {
            XCTFail("Properties should not be nil")
            return
        }

        XCTAssertNil(properties["key"])
        XCTAssertNotNil(properties["\(AnalyticsUserProfile.AWSPinpoint.Endpoint.userAttributePrefix)key"])
        XCTAssertEqual(userProfile.endpointUserProperties?.count, 1)
        XCTAssertTrue(userProfile.endpointCustomProperties?.isEmpty ?? false)
    }

    /// Given: A AnalyticsUserProfile
    /// When: AnalyticsUserProfile.addPinpointUserProperties() is invoked with a dictionary containg pairs of keys and values
    /// Then: Each key is prefixed with a custom attribute prefix
    ///      and each pair is included in AnalyticsUserProfile.endpointUserProperties, without any prefix
    ///      and each pair is not included in AnalyticsUserProfile.endpointCustomProperties
    func testAddPinpointEndpointUserProperties_shouldAddPrefixes() {
        var userProfile = AnalyticsUserProfile()
        userProfile.addPinpointUserProperties([
            "attributeKey": "string",
            "metricKey": 2
        ])

        guard let properties = userProfile.properties else {
            XCTFail("Properties should not be nil")
            return
        }

        XCTAssertNil(properties["attributeKey"])
        XCTAssertNotNil(properties["\(AnalyticsUserProfile.AWSPinpoint.Endpoint.userAttributePrefix)attributeKey"])
        XCTAssertNotNil(properties["\(AnalyticsUserProfile.AWSPinpoint.Endpoint.userAttributePrefix)metricKey"])
        XCTAssertEqual(userProfile.endpointUserProperties?.count, 2)
        XCTAssertTrue(userProfile.endpointCustomProperties?.isEmpty ?? false)
    }

    /// Given: A AnalyticsUserProfile is created with properties whose keys that don't include any prefix.
    /// When: AnalyticsUserProfile.endpointCustomProperties is invoked
    /// Then: The properties that were missing a prefix are included
    func testProperties_withoutPrefix_shouldBeAddedToEndpointCustomProperties() {
        let userProfile = AnalyticsUserProfile(properties: [
            "key": "value",
            "\(AnalyticsUserProfile.AWSPinpoint.Endpoint.userAttributePrefix)userKey1": "userValue1",
        ])

        XCTAssertEqual(userProfile.endpointCustomProperties?.count, 1)
    }

    /// Given: A AnalyticsUserProfile is created with properties whose keys have prefixes
    /// When: AnalyticsUserProfile.endpointCustomProperties and AnalyticsUserProfile.endpointUserProperties are invoked
    /// Then: The properties are filtered out accordingly to their keys prefix
    func testEndpointCustomAndUserProperties_shouldFilterOutOtherProperties() {
        let userProfile = AnalyticsUserProfile(properties: [
            "\(AnalyticsUserProfile.AWSPinpoint.Endpoint.userAttributePrefix)userKey1": "userValue1",
            "\(AnalyticsUserProfile.AWSPinpoint.Endpoint.userAttributePrefix)userKey2": "userValue2",
            "\(AnalyticsUserProfile.AWSPinpoint.Endpoint.customAttributePrefix)endpointKey1": "endpointValue1",
            "\(AnalyticsUserProfile.AWSPinpoint.Endpoint.customAttributePrefix)endpointKey2": 2,
            "endpointKey3": "endpointValue3",
        ])

        guard let properties = userProfile.properties,
              let endpointProperties = userProfile.endpointCustomProperties,
              let userProperties = userProfile.endpointUserProperties else {
            XCTFail("Properties should not be nil")
            return
        }

        XCTAssertEqual(properties.count, 5)
        XCTAssertEqual(userProperties.count, 2)
        XCTAssertEqual(endpointProperties.count, 3)

        XCTAssertFalse(userProperties.contains(where: {$0.key == "endpointKey3"}))
        XCTAssertFalse(endpointProperties.contains(where: {$0.key == "userKey1"}))
    }

    /// Given: A AnalyticsUserProfile is created with properties whose keys have prefixes that are not recognized
    /// When: AnalyticsUserProfile.endpointCustomProperties and AnalyticsUserProfile.endpointUserProperties are invoked
    /// Then: The properties with unrecognized prefixes are included in endpointCustomProperties without modification
    func testEndpointCustomAndUserProperties_withUnrecognizedPrefixes_shouldIncludeThemAsCustomProperties() {
        let userProfile = AnalyticsUserProfile(properties: [
            "\(AnalyticsUserProfile.AWSPinpoint.Endpoint.userAttributePrefix)userKey1": "userValue1",
            "\(AnalyticsUserProfile.AWSPinpoint.Endpoint.customAttributePrefix)endpointKey1": "endpointValue1",
            "unknownPrefix1::unknownKey1": "unknownValue1",
            "unknownPrefix2::unknownKey2": "unknownValue2"
        ])

        guard let properties = userProfile.properties,
              let endpointProperties = userProfile.endpointCustomProperties,
              let userProperties = userProfile.endpointUserProperties else {
            XCTFail("Properties should not be nil")
            return
        }

        XCTAssertEqual(properties.count, 4)
        XCTAssertEqual(userProperties.count, 1)
        XCTAssertEqual(endpointProperties.count, 3)

        XCTAssertFalse(userProperties.contains(where: {$0.key == "unknownPrefix1::unknownKey1"}))
        XCTAssertFalse(userProperties.contains(where: {$0.key == "unknownPrefix2::unknownKey2"}))
        XCTAssertFalse(userProperties.contains(where: {$0.key == "unknownKey1"}))
        XCTAssertFalse(userProperties.contains(where: {$0.key == "unknownKey2"}))

        XCTAssertTrue(endpointProperties.contains(where: {$0.key == "unknownPrefix1::unknownKey1"}))
        XCTAssertTrue(endpointProperties.contains(where: {$0.key == "unknownPrefix2::unknownKey2"}))
        XCTAssertFalse(endpointProperties.contains(where: {$0.key == "unknownKey1"}))
        XCTAssertFalse(endpointProperties.contains(where: {$0.key == "unknownKey2"}))
    }
}
