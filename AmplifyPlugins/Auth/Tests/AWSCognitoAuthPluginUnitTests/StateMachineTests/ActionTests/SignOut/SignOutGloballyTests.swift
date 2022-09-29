//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoIdentityProvider
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon

class SignOutGloballyTests: XCTestCase {

    func testGlobalSignOutInvoked() async {
        let globalSignOutInvoked = expectation(description: "globalSignOutInvoked")
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockGlobalSignOutResponse: { _ in
                    globalSignOutInvoked.fulfill()
                    return try GlobalSignOutOutputResponse(httpResponse: MockHttpResponse.ok)
                }
            )
        }

        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics
        )
        let action = SignOutGlobally(signedInData: .testData, hostedUIError: nil)

        await action.execute(
            withDispatcher: MockDispatcher { _ in },
            environment: environment
        )

        await waitForExpectations(timeout: 0.1)
    }

    func testFailedGlobalSignOutTriggersBuildRevokeError() async {
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockGlobalSignOutResponse: { _ in
                    throw NSError(domain: "testError", code: 0, userInfo: nil)
                }
            )
        }

        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics
        )

        let action = SignOutGlobally(signedInData: .testData, hostedUIError: nil)

        let revokeTokenEventSent = expectation(description: "revokeTokenEventSent")
        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignOutEvent else {
                XCTFail("Expected event to be SignOutEvent")
                return
            }

            if case .globalSignOutError(let signInData, _, _) = event.eventType {
                XCTAssertNotNil(signInData)
                revokeTokenEventSent.fulfill()
            }
        }

        await action.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        await waitForExpectations(timeout: 0.1)
    }

    func testSuccessfulGlobalSignOutTriggersRevokeToken() async {
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockGlobalSignOutResponse: { _ in
                    return try GlobalSignOutOutputResponse(httpResponse: MockHttpResponse.ok)
                }
            )
        }

        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics
        )

        let action = SignOutGlobally(signedInData: .testData, hostedUIError: nil)

        let revokeTokenEventSent = expectation(description: "revokeTokenEventSent")
        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignOutEvent else {
                XCTFail("Expected event to be SignOutEvent")
                return
            }

            if case let .revokeToken(signInData, _, _) = event.eventType {
                XCTAssertNotNil(signInData)
                revokeTokenEventSent.fulfill()
            }
        }

        await action.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        await waitForExpectations(timeout: 0.1)
    }

}
