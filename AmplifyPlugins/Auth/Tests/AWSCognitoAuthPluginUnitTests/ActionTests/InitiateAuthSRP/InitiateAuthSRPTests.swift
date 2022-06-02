//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentityProvider

@testable import AWSCognitoAuthPlugin

class InitiateAuthSRPTests: XCTestCase {

    func testInitiate() {
        let initiateAuthInvoked = expectation(description: "initiateAuthInvoked")
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                initiateAuthCallback: { _ in
                    initiateAuthInvoked.fulfill()
                    return InitiateAuthOutputResponse()
                }
            )
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )
        let action = InitiateAuthSRP(username: "testUser", password: "testPassword")

        action.execute(
            withDispatcher: MockDispatcher { _ in },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testFailedInitiateAuthPropagatesError() {
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                initiateAuthCallback: { _ in
                    throw NSError(domain: "testError", code: 0, userInfo: nil)

                }
            )
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let action = InitiateAuthSRP(username: "testUser", password: "testPassword")

        let errorEventSent = expectation(description: "errorEventSent")
        let dispatcher = MockDispatcher { event in

            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent")
                return
            }

            if case let .throwAuthError(error) = event.eventType {
                XCTAssertNotNil(error)
                errorEventSent.fulfill()
            }

        }

        action.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testSuccessfulInitiateAuthPropagatesSuccess() {
        let identityProviderFactory: BasicSRPAuthEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                initiateAuthCallback: { _ in
                    return InitiateAuthOutputResponse()
                }
            )
        }

        let environment = BasicSRPAuthEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let action = InitiateAuthSRP(username: "testUser", password: "testPassword")

        let successEventSent = expectation(description: "successEventSent")

        let dispatcher = MockDispatcher { event in
            guard let event = event as? SRPSignInEvent else {
                XCTFail("Expected event to be SRPSignInEvent")
                return
            }

            if case let .respondPasswordVerifier(_, authResponse) = event.eventType {
                XCTAssertNotNil(authResponse)
                successEventSent.fulfill()
            }
        }

        action.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

}
