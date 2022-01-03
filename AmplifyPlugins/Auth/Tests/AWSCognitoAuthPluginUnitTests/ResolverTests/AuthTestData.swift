//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoAuthPlugin
import Foundation

extension AuthenticationEvent {

    static let allTestEvents = [
        AuthenticationEvent.configuredTest,
        .initializedSignedInTest,
        .initializedSignedOutTest,
        .signInRequestedTest,
        .errorTest
    ]

    static let configuredTest = AuthenticationEvent(
        id: "configuredTest",
        eventType: .configured(.testData)
    )

    static let initializedSignedInTest = AuthenticationEvent(
        id: "initializedSignedInTest",
        eventType: .initializedSignedIn(.testData)
    )

    static let initializedSignedOutTest = AuthenticationEvent(
        id: "initializedSignedOutTest",
        eventType: .initializedSignedOut(.testData)
    )

    static let signInRequestedTest = AuthenticationEvent(
        id: "signInRequestedTest",
        eventType: .signInRequested(.testData)
    )

//    static let srpAuthInitiatedTest = AuthenticationEvent(
//        id: "srpAuthInitiatedTest",
//        eventType: .srpAuthInitiated(.testData)
//    )

    static let errorTest = AuthenticationEvent(
        id: "errorTest",
        eventType: .error(.testData)
    )
}

// MARK: - Test Data

extension AuthConfiguration {
    static let testData = AuthConfiguration.userPools(.testData)
}

extension AuthenticationError {
    static let testData = AuthenticationError.configuration(message: "testAuthenticationError")
}

extension SignInEventData {
    static let testData = SignInEventData(username: "testUserName", password: "testPassword")
}

extension AWSCognitoUserPoolTokens {
    static let testData = AWSCognitoUserPoolTokens(
        idToken: "XX", accessToken: "XX", refreshToken: "XX", expiresIn: 300)
}

extension SignedInData {
    static let testData = SignedInData(
        userId: "testUserid",
        userName: "testUserName",
        signedInDate: Date(timeIntervalSince1970: 0),
        signInMethod: .srp,
        cognitoUserPoolTokens: AWSCognitoUserPoolTokens.testData
    )
}

extension SignedOutData {
    static let testData = SignedOutData(
        authenticationConfiguration: .testData,
        lastKnownUserName: nil
    )
}

extension SignInState {
    static let testData = SignInState.signingInWithSRP(.notStarted, SignInEventData(username: "", password: ""))
}

extension UserPoolConfigurationData {
    static let testData = UserPoolConfigurationData(
        poolId: "testPoolId",
        clientId: "testClientId",
        region: "region",
        clientSecret: "testClientSecret",
        pinpointAppId: nil
    )
}
