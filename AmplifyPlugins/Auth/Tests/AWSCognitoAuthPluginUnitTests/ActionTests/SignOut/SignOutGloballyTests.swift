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
class SignOutGloballyTests: XCTestCase, @unchecked Sendable {

    func testGlobalSignOutInvoked() async {
        let globalSignOutInvoked = expectation(description: "globalSignOutInvoked")
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockGlobalSignOutResponse: { _ in
                    globalSignOutInvoked.fulfill()
                    return GlobalSignOutOutput()
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

        await fulfillment(
            of: [globalSignOutInvoked],
            timeout: 0.1
        )
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

        await fulfillment(
            of: [revokeTokenEventSent],
            timeout: 0.1
        )
    }

    func testSuccessfulGlobalSignOutTriggersRevokeToken() async {
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockGlobalSignOutResponse: { _ in
                    return GlobalSignOutOutput()
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

        await fulfillment(
            of: [revokeTokenEventSent],
            timeout: 0.1
        )
    }

    /// A failed global sign-out keeps the exception it was made from
    ///
    /// - Given: `GlobalSignOut` failing with the user pool's `InternalErrorException`
    /// - When:
    ///    - the action runs
    /// - Then:
    ///    - the global sign-out failure's engine error is the exception's own `.unknown`, with nothing underneath, as
    ///      before
    ///    - its `cause` is the exception
    ///
    func testFailedGlobalSignOutKeepsTheExceptionAsTheCause() async throws {
        let identityProviderFactory: BasicUserPoolEnvironment.CognitoUserPoolFactory = {
            MockIdentityProvider(
                mockGlobalSignOutResponse: { _ in
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
        let action = SignOutGlobally(signedInData: .testData, hostedUIError: nil)
        let failures = TestBox<[EngineGlobalSignOutFailure]>([])
        let dispatcher = MockDispatcher { event in
            if case .globalSignOutError(_, let globalSignOutError, _) = (event as? SignOutEvent)?.eventType {
                failures.with { $0.append(globalSignOutError) }
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
