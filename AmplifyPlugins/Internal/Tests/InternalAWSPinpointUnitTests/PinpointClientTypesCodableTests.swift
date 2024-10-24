//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
@testable import InternalAWSPinpoint
import XCTest

class PinpointClientTypesCodableTests: XCTestCase {
    /// Given: Instances of PinpointClient types that conform to Codable
    /// When: They are encoded and decoded
    /// Then: The encoded data can be decoded, and the decoded data is equal to the original one
    func testCodableTypes_shouldEncodeAndDecodeSuccesfully() throws {
        let location = PinpointClientTypes.EndpointLocation(
            city: "city",
            country: "country",
            latitude: 10.0,
            longitude: 10.0,
            postalCode: "postalCode",
            region: "region"
        )

        let demographic = PinpointClientTypes.EndpointDemographic(
            appVersion: "appVersion",
            locale: "locale",
            make: "make",
            model: "model",
            modelVersion: "modelVersion",
            platform: "platform",
            platformVersion: "platformVersion",
            timezone: "timezone"
        )

        let user = PinpointClientTypes.EndpointUser(
            userAttributes: [
                "attributes": ["value1", "value2"]
            ],
            userId: "userId"
        )

        let archiver = AmplifyArchiver()

        // Encode types
        let encodedLocation = try archiver.encode(location)
        let encodedDemographic = try archiver.encode(demographic)
        let encodedUser = try archiver.encode(user)

        // Decode types
        let decodedLocation = try archiver.decode(
            PinpointClientTypes.EndpointLocation.self,
            from: encodedLocation
        )
        XCTAssertEqual(decodedLocation, location)

        let decodedDemographic = try archiver.decode(
            PinpointClientTypes.EndpointDemographic.self,
            from: encodedDemographic
        )
        XCTAssertEqual(decodedDemographic, demographic)

        let decodedUser = try archiver.decode(
            PinpointClientTypes.EndpointUser.self,
            from: encodedUser
        )
        XCTAssertEqual(decodedUser, user)
    }
}
