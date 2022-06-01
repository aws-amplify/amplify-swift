//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider

@testable import AWSCognitoAuthPlugin

class RefreshUserPoolTokensTests: XCTestCase {

    func testNoUserPoolEnvironment() {

        let expectation = expectation(description: "noUserPoolEnvironment")

        let action = RefreshUserPoolTokens(cognitoSession: AWSAuthCognitoSession.testData)

        action.execute(
            withDispatcher: MockDispatcher { event in

                guard let event = event as? FetchUserPoolTokensEvent else {
                    return
                }

                if case let .throwError(error) = event.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, AuthorizationError.configuration(message: AuthPluginErrorConstants.configurationError))
                    expectation.fulfill()
                }
            },
            environment: MockInvalidEnvironment()
        )

        waitForExpectations(timeout: 0.1)
    }

    func testNoUserPoolTokensToRefresh() {

        let expectation = expectation(description: "noUserPoolTokens")

        let action = RefreshUserPoolTokens(cognitoSession: AWSAuthCognitoSession.testData)

        let environment = Defaults.makeDefaultAuthEnvironment()

        action.execute(
            withDispatcher: MockDispatcher { event in

                guard let event = event as? FetchUserPoolTokensEvent else {
                    return
                }

                if case let .throwError(error) = event.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, AuthorizationError.service(error: AuthError.unknown("", nil)))
                    expectation.fulfill()
                }
            },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testInvalidSuccessfulResponse() {

        let expectation = expectation(description: "refreshUserPoolTokens")
        let cognitoSessionInput = AWSAuthCognitoSession.testData
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                initiateAuthCallback: { _, callback in
                    let response = InitiateAuthOutputResponse()
                    callback(.success(response))
                }
            )
        }

        let environment = BasicUserPoolEnvironment(userPoolConfiguration: UserPoolConfigurationData.testData,
                                                   cognitoUserPoolFactory: identityProviderFactory)

        let action = RefreshUserPoolTokens(cognitoSession: cognitoSessionInput)

        action.execute(
            withDispatcher: MockDispatcher { event in

                guard let event = event as? FetchUserPoolTokensEvent else {
                    return
                }

                if case let .throwError(error) = event.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, AuthorizationError.invalidUserPoolTokens(message: "UserPoolTokens are invalid."))
                    expectation.fulfill()
                }
            },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testValidSuccessfulResponse() {

        let fetchIdentityExpectation = expectation(description: "fetchIdentityEvent")
        let expectation = expectation(description: "refreshUserPoolTokens")

        let cognitoSessionInput = AWSAuthCognitoSession.testData
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                initiateAuthCallback: { _, callback in
                    let response = InitiateAuthOutputResponse(
                        authenticationResult: CognitoIdentityProviderClientTypes.AuthenticationResultType(
                            accessToken: "accessTokenNew",
                            expiresIn: 100,
                            idToken: "idTokenNew",
                            refreshToken: "refreshTokenNew"))
                    callback(.success(response))
                }
            )
        }

        let environment = BasicUserPoolEnvironment(userPoolConfiguration: UserPoolConfigurationData.testData,
                                                   cognitoUserPoolFactory: identityProviderFactory)

        let action = RefreshUserPoolTokens(cognitoSession: cognitoSessionInput)

        action.execute(
            withDispatcher: MockDispatcher { event in

                if let userPoolEvent = event as? FetchUserPoolTokensEvent,
                   case .fetched = userPoolEvent.eventType {
                    expectation.fulfill()
                } else if let authSessionEvent = event as? FetchAuthSessionEvent,
                          case let .fetchIdentity(credentials) = authSessionEvent.eventType {
                    XCTAssertNotNil(credentials)
                    fetchIdentityExpectation.fulfill()
                }
            },
            environment: environment
        )
        waitForExpectations(timeout: 0.1)
    }

    func testFailureResponse() {

        let fetchIdentityExpectation = expectation(description: "fetchIdentityEvent")
        let expectation = expectation(description: "failureError")

        let testError = NSError(domain: "testError", code: 0, userInfo: nil)

        let cognitoSessionInput = AWSAuthCognitoSession.testData
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                initiateAuthCallback: { _, callback in
                    callback(.failure(.unknown(testError)))
                }
            )
        }

        let environment = BasicUserPoolEnvironment(userPoolConfiguration: UserPoolConfigurationData.testData,
                                                   cognitoUserPoolFactory: identityProviderFactory)

        let action = RefreshUserPoolTokens(cognitoSession: cognitoSessionInput)

        action.execute(
            withDispatcher: MockDispatcher { event in

                if let userPoolEvent = event as? FetchUserPoolTokensEvent,
                   case let .throwError(error) = userPoolEvent.eventType {
                    XCTAssertNotNil(error)
                    XCTAssertEqual(error, AuthorizationError.service(error: testError))
                    expectation.fulfill()
                } else if let authSessionEvent = event as? FetchAuthSessionEvent,
                          case let .fetchIdentity(credentials) = authSessionEvent.eventType {
                    XCTAssertNotNil(credentials)
                    fetchIdentityExpectation.fulfill()
                }
            },
            environment: environment
        )
        waitForExpectations(timeout: 0.1)
    }

}
