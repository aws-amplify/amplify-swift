//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin

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
        eventType: .configured
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

extension SignInError {
    static let testData = SignInError.configuration(message: "testSRPSignInError")
}

extension AuthenticationError {
    static let testData = AuthenticationError.configuration(message: "testAuthenticationError")
}

extension SignInEventData {
    static let testData = SignInEventData(username: "testUserName",
                                          password: "testPassword",
                                          signInMethod: .apiBased(.userSRP))
}

extension SignOutEventData {
    static let testData = SignOutEventData(globalSignOut: true)
}

extension SignedOutData {
    static let testData = SignedOutData(
        lastKnownUserName: "testUserName"
    )
}

extension SignInState {
    static let testData = SignInState.signingInWithSRP(.notStarted, SignInEventData(
        username: "",
        password: "",
        signInMethod:.apiBased(.userSRP)))
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

extension IdentityPoolConfigurationData {
    static let testData = IdentityPoolConfigurationData(poolId: "poolId",
                                                        region: "regionId")
}

struct MockInvalidEnvironment: Environment { }
