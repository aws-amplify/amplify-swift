//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSCognitoAuthPlugin

class AuthUserAttributeKeyTests: XCTestCase {

    /// Test if attribute raw value gives us the right value
    ///
    /// - Given: Any attribute from the enum AuthUserAttributeKey say .phoneNumber
    /// - When:
    ///    - I get rawValue of the enum
    /// - Then:
    ///    - The value should be equal to the one defined by Cognito.
    ///    https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-attributes.html
    ///
    func testSuccessfulRawValue() {
        let attribute = AuthUserAttributeKey.phoneNumber
        XCTAssertEqual(attribute.rawValue, "phone_number")
    }

    /// Test if initializing through a valid raw string gives back an enum
    ///
    /// - Given: A valid raw string from the Cognito
    /// - When:
    ///    - I create an enum using the raw value
    /// - Then:
    ///    - The enum should be mapping to the exact value
    ///
    func testInitWithRawValue() {
        let attribute = AuthUserAttributeKey(rawValue: "middle_name")
        XCTAssertEqual(attribute, .middleName)
    }

    /// Test if initializing through a custom raw string gives back an enum
    ///
    /// - Given: A custom raw string to be used as custom attribute
    /// - When:
    ///    - I create an enum using the raw value
    /// - Then:
    ///    - The enum should be custom attribute type
    ///
    func testInitWithCustomRawValue() {
        let attribute = AuthUserAttributeKey(rawValue: "custom:someattribute")
        switch attribute {
        case .custom(let attribute):
            print(attribute)
        default:
            XCTFail("Attribute type should be custom")
        }
    }

    /// Test if attribute raw value gives us the right value for a custom attribute
    ///
    /// - Given: A custom attribute from AuthUserAttributeKey
    /// - When:
    ///    - I get rawValue of the enum
    /// - Then:
    ///    - The value should be equal to "custom:<value given>"
    ///
    func testSuccessfulCustomRawValue() {
        let customAttributeKey = "someattribute2"
        let attribute = AuthUserAttributeKey.custom(customAttributeKey)
        XCTAssertEqual(attribute.rawValue, "custom:\(customAttributeKey)")
    }

    /// Test if attribute raw value gives us the right value for a unknown attribute
    ///
    /// - Given: A unknown attribute from AuthUserAttributeKey
    /// - When:
    ///    - I get rawValue of the enum
    /// - Then:
    ///    - The value should be equal to "<value given>"
    ///
    func testSuccessfulUnknownRawValue() {
        let customAttributeKey = "someattribute2"
        let attribute = AuthUserAttributeKey.unknown(customAttributeKey)
        XCTAssertEqual(attribute.rawValue, customAttributeKey)
    }

    /// Test if initializing through a unknown raw string gives back an enum
    ///
    /// - Given: A raw string wihtout the custom attribute prefix
    /// - When:
    ///    - I create an enum using the raw value
    /// - Then:
    ///    - The enum should be unknown attribute type
    ///
    func testInitWithUnkownRawValue() {
        let attribute = AuthUserAttributeKey(rawValue: "someattribute")
        switch attribute {
        case .unknown(let attribute):
            print(attribute)
        default:
            XCTFail("Attribute type should be custom")
        }
    }
}
