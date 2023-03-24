//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

import AWSCognitoIdentityProvider

class ConfirmSignUpInputTests: XCTestCase {

    func testConfirmSignUpInputWithClientSecretAndAsfDeviceId() throws {
        let username = "jeff"
        let clientSecret = UUID().uuidString
        let userPoolConfiguration = UserPoolConfigurationData(poolId: "",
                                                              clientId: "123456",
                                                              region: "",
                                                              clientSecret: clientSecret)
        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: userPoolConfiguration,
            cognitoUserPoolFactory: Defaults.makeDefaultUserPool,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics)

        let confirmSignUpInput = ConfirmSignUpInput(
            username: username,
            confirmationCode: "123",
            clientMetadata: [:],
            asfDeviceId: "asdfDeviceId",
            environment: environment)

        XCTAssertNotNil(confirmSignUpInput.secretHash)
        XCTAssertNotNil(confirmSignUpInput.userContextData)
    }

    func testConfirmSignUpInputWithoutClientSecretAndAsfDeviceId() throws {
        let username = "jeff"

        let userPoolConfiguration = UserPoolConfigurationData(poolId: "",
                                                              clientId: "123456",
                                                              region: "",
                                                              clientSecret: nil)
        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: userPoolConfiguration,
            cognitoUserPoolFactory: Defaults.makeDefaultUserPool,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics)

        let confirmSignUpInput = ConfirmSignUpInput(
            username: username,
            confirmationCode: "123",
            clientMetadata: [:],
            asfDeviceId: nil,
            environment: environment)

        XCTAssertNil(confirmSignUpInput.secretHash)
        XCTAssertNil(confirmSignUpInput.userContextData)
    }
}
