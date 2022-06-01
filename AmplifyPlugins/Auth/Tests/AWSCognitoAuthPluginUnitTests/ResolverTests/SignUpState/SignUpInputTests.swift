//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

import AWSCognitoIdentityProvider

class SignUpInputTests: XCTestCase {

    func testSignUpInputWithClientSecret() throws {
        let username = "jeff"
        let password = "a2z"
        let clientSecret = UUID().uuidString
        let userPoolConfiguration = UserPoolConfigurationData(poolId: "",
                                                              clientId: "123456",
                                                              region: "",
                                                              clientSecret: clientSecret)
        let input = SignUpInput(username: username,
                                password: password,
                                attributes: [:],
                                userPoolConfiguration: userPoolConfiguration)

        XCTAssertNotNil(input.secretHash)
    }

    func testSignUpInputWithoutClientSecret() throws {
        let username = "jeff"
        let password = "a2z"
        let userPoolConfiguration = UserPoolConfigurationData(poolId: "",
                                                              clientId: "123456",
                                                              region: "",
                                                              clientSecret: nil)
        let input = SignUpInput(username: username,
                                password: password,
                                attributes: [:],
                                userPoolConfiguration: userPoolConfiguration)

        XCTAssertNil(input.secretHash)
    }

    func testSignUpInputValidationData() throws {
        #if canImport(UIKit)
        let username = "jeff"
        let password = "a2z"
        let clientSecret = UUID().uuidString
        let userPoolConfiguration = UserPoolConfigurationData(poolId: "",
                                                              clientId: "123456",
                                                              region: "",
                                                              clientSecret: clientSecret)
        let input = SignUpInput(username: username,
                                password: password,
                                attributes: [:],
                                userPoolConfiguration: userPoolConfiguration)
        XCTAssertNotNil(input.validationData)
        XCTAssertGreaterThan(input.validationData?.count ?? 0, 0)
        if let validationData = input.validationData {
            assertHasAttributeType(name: "cognito:iOSVersion", validationData: validationData)
            assertHasAttributeType(name: "cognito:systemName", validationData: validationData)
            assertHasAttributeType(name: "cognito:deviceName", validationData: validationData)
            assertHasAttributeType(name: "cognito:model", validationData: validationData)
        }
        #else
        XCTSkip("Skipping test when not iOS")
        #endif
    }

    func assertHasAttributeType(name: String,
                                validationData: [CognitoIdentityProviderClientTypes.AttributeType],
                                file: StaticString = #file, line: UInt = #line)
    {

        let attribute = validationData.first(where: { $0.name == name })
        XCTAssertNotNil(attribute, "Attribute not found for name: \(name)", file: file, line: line)
    }

}
