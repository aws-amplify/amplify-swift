//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentityProvider
@testable import AWSPluginsTestCommon
@testable import AWSCognitoAuthPlugin

class RevokeTokenTests: XCTestCase {

    func testRevokeTokenInvoked() {
        let revokeTokenInvoked = expectation(description: "revokeTokenInvoked")
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockRevokeTokenResponse: { _ in
                    revokeTokenInvoked.fulfill()
                    return try RevokeTokenOutputResponse(httpResponse: MockHttpResponse.ok)
                }
            )
        }

        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )
        let action = RevokeToken(signedInData: .testData)

        action.execute(
            withDispatcher: MockDispatcher { _ in },
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testFailedRevokeTokenTriggersClearCredentialStore() {
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockRevokeTokenResponse: { _ in
                    throw NSError(domain: "testError", code: 0, userInfo: nil)
                }
            )
        }

        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let action = RevokeToken(signedInData: .testData)

        let clearCredentialStoreEventSent = expectation(description: "clearCredentialStoreEventSent")
        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignOutEvent else {
                XCTFail("Expected event to be SignOutEvent")
                return
            }

            if case let .signOutLocally(signInData) = event.eventType {
                XCTAssertNotNil(signInData)
                clearCredentialStoreEventSent.fulfill()
            }
        }

        action.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

    func testSuccessfulRevokeTokenTriggersClearCredentialStore() {
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockRevokeTokenResponse: { _ in
                    return try RevokeTokenOutputResponse(httpResponse: MockHttpResponse.ok)
                }
            )
        }

        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory
        )

        let action = RevokeToken(signedInData: .testData)

        let clearCredentialStoreEventSent = expectation(description: "clearCredentialStoreEventSent")
        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignOutEvent else {
                XCTFail("Expected event to be SignOutEvent")
                return
            }

            if case let .signOutLocally(signInData) = event.eventType {
                XCTAssertNotNil(signInData)
                clearCredentialStoreEventSent.fulfill()
            }
        }

        action.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        waitForExpectations(timeout: 0.1)
    }

}
