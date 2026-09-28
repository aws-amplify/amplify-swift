//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAWSCognitoAuth
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

class UserPoolConfigurationDataAmplifyOutputsTests: XCTestCase {

    /// Every standard attribute in `amplify_outputs.json` maps to the sign-up attribute it always has.
    ///
    /// - Given: Each case of `AmplifyOutputsData.AmazonCognitoStandardAttributes`
    /// - When:
    ///    - `UserPoolConfigurationData.SignUpAttributeType(from:)` maps it
    /// - Then:
    ///    - The 13 attributes the Authenticator offers at sign-up map to their sign-up attribute
    ///    - `locale`, `picture`, `sub`, `updated_at` and `zoneinfo` map to `nil`
    ///
    func testSignUpAttributeTypeFromEveryStandardAttribute() {
        let expected: [(AmplifyOutputsData.AmazonCognitoStandardAttributes, UserPoolConfigurationData.SignUpAttributeType?)] = [
            (.address, .address),
            (.birthdate, .birthDate),
            (.email, .email),
            (.familyName, .familyName),
            (.gender, .gender),
            (.givenName, .givenName),
            (.locale, nil),
            (.middleName, .middleName),
            (.name, .name),
            (.nickname, .nickname),
            (.phoneNumber, .phoneNumber),
            (.picture, nil),
            (.preferredUsername, .preferredUsername),
            (.profile, .profile),
            (.sub, nil),
            (.updatedAt, nil),
            (.website, .website),
            (.zoneinfo, nil)
        ]
        XCTAssertEqual(Set(expected.map(\.0.rawValue)).count, expected.count, "an attribute is listed twice")
        for (attribute, signUpAttribute) in expected {
            listedAbove(attribute)
            XCTAssertEqual(
                UserPoolConfigurationData.SignUpAttributeType(from: attribute),
                signUpAttribute,
                "\(attribute)"
            )
        }
    }

    /// Stops compiling when a standard attribute is added, so whoever adds one comes here and gives it a row
    /// in the table above.
    private func listedAbove(_ attribute: AmplifyOutputsData.AmazonCognitoStandardAttributes) {
        switch attribute {
        case .address, .birthdate, .email, .familyName, .gender, .givenName, .locale, .middleName, .name,
             .nickname, .phoneNumber, .picture, .preferredUsername, .profile, .sub, .updatedAt, .website, .zoneinfo:
            break
        }
    }
}
