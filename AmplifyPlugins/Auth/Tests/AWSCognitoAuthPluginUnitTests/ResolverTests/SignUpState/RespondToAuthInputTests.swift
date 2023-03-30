//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin

import AWSCognitoIdentityProvider

class RespondToAuthInputTests: XCTestCase {

    func testDevicePasswordVerifierInput() throws {
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

        let respondToAuthChallengeInput = RespondToAuthChallengeInput.devicePasswordVerifier(
            username: username,
            stateData: .testData,
            session: "session",
            secretBlock: "secret",
            signature: "signature",
            deviceMetadata: .metadata(.init(deviceKey: "", deviceGroupKey: "")),
            asfDeviceId: "asfDeviceId",
            environment: environment)

        XCTAssertNotNil(respondToAuthChallengeInput.challengeResponses?["SECRET_HASH"])
        XCTAssertNotNil(respondToAuthChallengeInput.userContextData)
    }

    func testVerifyChallengeInput() throws {
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

        let respondToAuthChallengeInput = RespondToAuthChallengeInput.verifyChallenge(
            username: username,
            challengeType: .smsMfa,
            session: "session",
            responseKey: "CODE",
            answer: "1234",
            clientMetadata: [:],
            asfDeviceId: "asfDeviceId",
            attributes: [:],
            deviceMetadata: .metadata(.init(deviceKey: "", deviceGroupKey: "")),
            environment: environment)

        XCTAssertEqual(respondToAuthChallengeInput.challengeResponses?["CODE"], "1234")
        XCTAssertNotNil(respondToAuthChallengeInput.userContextData)
    }

    func testPasswordVerifierInput() throws {
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

        let respondToAuthChallengeInput = RespondToAuthChallengeInput.passwordVerifier(
            username: username,
            stateData: .testData,
            session: "session",
            secretBlock: "secret",
            signature: "signature",
            deviceMetadata: .metadata(.init(deviceKey: "", deviceGroupKey: "")),
            asfDeviceId: "asfDeviceId",
            environment: environment)

        XCTAssertNotNil(respondToAuthChallengeInput.challengeResponses?["PASSWORD_CLAIM_SECRET_BLOCK"])
        XCTAssertNotNil(respondToAuthChallengeInput.challengeResponses?["PASSWORD_CLAIM_SIGNATURE"])
        XCTAssertNotNil(respondToAuthChallengeInput.userContextData)
    }

    func testDeviceSrpInput() throws {
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

        let respondToAuthChallengeInput = RespondToAuthChallengeInput.deviceSRP(
            username: username,
            environment: environment,
            deviceMetadata: .metadata(.init(deviceKey: "", deviceGroupKey: "")),
            asfDeviceId: "asfDeviceId",
            session: "session",
            publicHexValue: "somehexValue")

        XCTAssertEqual(respondToAuthChallengeInput.challengeResponses?["SRP_A"], "somehexValue")
        XCTAssertNotNil(respondToAuthChallengeInput.userContextData)
    }

}
