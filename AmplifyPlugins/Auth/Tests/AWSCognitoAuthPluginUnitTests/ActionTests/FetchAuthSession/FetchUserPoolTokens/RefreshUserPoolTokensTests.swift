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

    func testNoUserPoolEnvironment() async {

        let expectation = expectation(description: "noUserPoolEnvironment")

        let action = RefreshUserPoolTokens(existingSignedIndata: .testData)

        await action.execute(withDispatcher: MockDispatcher { event in

            guard let event = event as? RefreshSessionEvent else {
                return
            }

            if case let .throwError(error) = event.eventType {
                XCTAssertNotNil(error)
                XCTAssertEqual(error, .noUserPool)
                expectation.fulfill()
            }
        }, environment: MockInvalidEnvironment()
        )

        await waitForExpectations(timeout: 0.1)
    }

    func testInvalidSuccessfulResponse() async {

        let expectation = expectation(description: "refreshUserPoolTokens")
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockInitiateAuthResponse: { _ in
                    return InitiateAuthOutputResponse()
                }
            )
        }

        let action = RefreshUserPoolTokens(existingSignedIndata: .testData)

        await action.execute(withDispatcher: MockDispatcher { event in

            guard let event = event as? RefreshSessionEvent else { return }

            if case let .throwError(error) = event.eventType {
                XCTAssertNotNil(error)
                XCTAssertEqual(error, .invalidTokens)
                expectation.fulfill()
            }
        }, environment: Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)
        )

        await waitForExpectations(timeout: 1)
    }

    func testValidSuccessfulResponse() async {

        let expectation = expectation(description: "refreshUserPoolTokens")
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockInitiateAuthResponse: { _ in
                    return InitiateAuthOutputResponse(
                        authenticationResult: .init(
                            accessToken: "accessTokenNew",
                            expiresIn: 100,
                            idToken: "idTokenNew",
                            refreshToken: "refreshTokenNew"))
                }
            )
        }

        let action = RefreshUserPoolTokens(existingSignedIndata: .testData)

        await action.execute(withDispatcher: MockDispatcher { event in

            if let userPoolEvent = event as? RefreshSessionEvent,
               case .refreshIdentityInfo = userPoolEvent.eventType {
                expectation.fulfill()
            }
        }, environment: Defaults.makeDefaultAuthEnvironment(
            userPoolFactory: identityProviderFactory)
        )
        await waitForExpectations(timeout: 0.1)
    }

    func testFailureResponse() async {

        let expectation = expectation(description: "failureError")

        let testError = NSError(domain: "testError", code: 0, userInfo: nil)

        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockInitiateAuthResponse: { _ in
                    throw testError
                }
            )
        }

        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: UserPoolConfigurationData.testData,
            cognitoUserPoolFactory: identityProviderFactory,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF)

        let action = RefreshUserPoolTokens(existingSignedIndata: .testData)

        await action.execute(withDispatcher: MockDispatcher { event in

            if let userPoolEvent = event as? RefreshSessionEvent,
               case let .throwError(error) = userPoolEvent.eventType {
                XCTAssertNotNil(error)
                XCTAssertEqual(error, .service(testError))
                expectation.fulfill()
            }
        }, environment: environment)

        await waitForExpectations(timeout: 0.1)
    }

}
