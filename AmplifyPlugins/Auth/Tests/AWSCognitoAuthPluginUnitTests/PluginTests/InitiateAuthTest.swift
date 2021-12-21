//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

////
////  InitiateAuthIntegTests.swift
////  aws-cognito-auth-pluginTests
////
////  Created by Schmelter, Tim on 12/30/20.
////
//
//import XCTest
//
//import AWSCognitoIdentityProvider
//import hierarchical_state_machine_swift
//
//import AWSCognitoAuthPlugin
//
//class InitiateAuthTests: XCTestCase {
//
//    func testInitiateAuthCommandThrowsError() {
//        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(
//            clientId: "clientId123",
//            clientSecret: "clientSecret123",
//            poolId: "us-west-2_poolid123",
//            shouldProvideCognitoValidationData: true,
//            pinpointAppId: nil,
//            migrationEnabled: false
//        )
//
//        let factory: () -> AWSCognitoIdentityProviderBehavior = {
//            MockIdentityProvider()
//        }
//
//        let environment = SRPAuthEnvironment(
//            userPoolConfiguration: userPoolConfiguration,
//            identityProviderFactory: factory
//        )
//
//        let stateMachine = StateMachine(
//            resolver: AuthenticationState.Resolver(),
//            environment: environment
//        )
//
//        let initiateAuthFailed = expectation(description: "initiateAuthFailed")
//
//        _ = stateMachine.listen { state in
//            if case .error = state {
//                initiateAuthFailed.fulfill()
//            }
//        }
//
//        let signInRequestedEvent = AuthenticationEvent(
//            id: "testSignIn",
//            eventType: .signInRequested(SignInEventData(username: "user", password: "password"))
//        )
//
//        stateMachine.send(signInRequestedEvent)
//
//        waitForExpectations(timeout: 1.0)
//    }
//
//}
//
//class MockIdentityProvider: AWSCognitoIdentityProviderBehavior {
//    func initiateAuth(request: AWSCognitoIdentityProviderInitiateAuthRequest, completionHandler: (AWSCognitoIdentityProviderInitiateAuthResponse?, NSError?) -> Void) {
//        let error = NSError(
//            domain: AWSCognitoIdentityErrorDomain,
//            code: AWSCognitoIdentityErrorCode.accessDenied.rawValue,
//            userInfo: nil
//        )
//        completionHandler(nil, error)
//    }
//
//}
