//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
@testable import InternalAWSCognitoAuth

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class RevokeTokenTests: XCTestCase, @unchecked Sendable {

    func testRevokeTokenInvoked() async {
        let revokeTokenInvoked = expectation(description: "revokeTokenInvoked")
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockRevokeTokenResponse: { _ in
                    revokeTokenInvoked.fulfill()
                    return RevokeTokenOutput()
                }
            )
        }

        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics
        )
        let action = RevokeToken(
            signedInData: .testData,
            hostedUIError: nil,
            globalSignOutError: nil
        )

        await action.execute(
            withDispatcher: MockDispatcher { _ in },
            environment: environment
        )

        await fulfillment(
            of: [revokeTokenInvoked],
            timeout: 0.1
        )
    }

    func testFailedRevokeTokenTriggersClearCredentialStore() async {
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockRevokeTokenResponse: { _ in
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

        let action = RevokeToken(
            signedInData: .testData,
            hostedUIError: nil,
            globalSignOutError: nil
        )

        let clearCredentialStoreEventSent = expectation(description: "clearCredentialStoreEventSent")
        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignOutEvent else {
                XCTFail("Expected event to be SignOutEvent")
                return
            }

            if case let .signOutLocally(signInData, _, _, _) = event.eventType {
                XCTAssertNotNil(signInData)
                clearCredentialStoreEventSent.fulfill()
            }
        }

        await action.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        await fulfillment(
            of: [clearCredentialStoreEventSent],
            timeout: 0.1
        )
    }

    func testSuccessfulRevokeTokenTriggersClearCredentialStore() async {
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockRevokeTokenResponse: { _ in
                    return RevokeTokenOutput()
                }
            )
        }

        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics
        )

        let action = RevokeToken(
            signedInData: .testData,
            hostedUIError: nil,
            globalSignOutError: nil
        )

        let clearCredentialStoreEventSent = expectation(description: "clearCredentialStoreEventSent")
        let dispatcher = MockDispatcher { event in
            guard let event = event as? SignOutEvent else {
                XCTFail("Expected event to be SignOutEvent")
                return
            }

            if case let .signOutLocally(signInData, _, _, _) = event.eventType {
                XCTAssertNotNil(signInData)
                clearCredentialStoreEventSent.fulfill()
            }
        }

        await action.execute(
            withDispatcher: dispatcher,
            environment: environment
        )

        await fulfillment(
            of: [clearCredentialStoreEventSent],
            timeout: 0.1
        )
    }

    /// A failed revoke keeps the exception it was made from
    ///
    /// - Given: `RevokeToken` failing with the user pool's `InternalErrorException`
    /// - When:
    ///    - the action runs
    /// - Then:
    ///    - the revoke failure's engine error is the exception's own `.unknown`, with nothing underneath, as before
    ///    - its `cause` is the exception
    ///
    func testFailedRevokeTokenKeepsTheExceptionAsTheCause() async throws {
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockRevokeTokenResponse: { _ in
                    throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
                }
            )
        }
        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: identityProviderFactory,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics
        )
        let action = RevokeToken(signedInData: .testData, hostedUIError: nil, globalSignOutError: nil)
        let failures = TestBox<[EngineRevokeTokenFailure]>([])
        let dispatcher = MockDispatcher { event in
            if case .signOutLocally(_, _, _, let revokeTokenError?) = (event as? SignOutEvent)?.eventType {
                failures.with { $0.append(revokeTokenError) }
            }
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)

        let failure = try XCTUnwrap(failures.get().first)
        guard case .unknown(let message, let underlying) = failure.error else {
            return XCTFail("expected .unknown, got \(failure.error)")
        }
        XCTAssertEqual(message, "boom")
        XCTAssertNil(underlying)
        XCTAssertTrue(failure.cause is AWSCognitoIdentityProvider.InternalErrorException, "\(String(describing: failure.cause))")
    }

}
