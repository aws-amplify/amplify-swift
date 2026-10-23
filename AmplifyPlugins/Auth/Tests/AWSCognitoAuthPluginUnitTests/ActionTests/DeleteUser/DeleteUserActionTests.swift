//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The engine's `DeleteUser` action and its resolver keep the exception a failed deletion was made from beside the
/// engine error, which keeps nothing under some exceptions (Cognito's `InternalErrorException`).
///
/// - Note: `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
///   `@Sendable` closures the mocks take. XCTest runs one test at a time.
final class DeleteUserActionTests: XCTestCase, @unchecked Sendable {

    /// A failed deletion keeps the exception it was made from
    ///
    /// - Given: `DeleteUser` failing with the user pool's `InternalErrorException`
    /// - When:
    ///    - the action runs
    /// - Then:
    ///    - it sends `throwError` with the exception's own `.unknown`, with nothing underneath, as before
    ///    - and the exception as the cause
    ///
    func testFailedDeletionKeepsTheExceptionAsTheCause() async throws {
        let environment = BasicUserPoolEnvironment(
            userPoolConfiguration: Defaults.makeDefaultUserPoolConfigData(),
            cognitoUserPoolFactory: {
                MockIdentityProvider(mockDeleteUserOutput: { _ in
                    throw AWSCognitoIdentityProvider.InternalErrorException(message: "boom")
                })
            },
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics
        )
        let sent = expectation(description: "throwError sent")
        let events = TestBox<[DeleteUserEvent.EventType]>([])
        let dispatcher = MockDispatcher { event in
            guard let eventType = (event as? DeleteUserEvent)?.eventType else {
                return
            }
            events.with { $0.append(eventType) }
            sent.fulfill()
        }

        await DeleteUser(accessToken: "access-token").execute(withDispatcher: dispatcher, environment: environment)
        await fulfillment(of: [sent], timeout: 5)

        guard case .throwError(.unknown(let message, let underlying), let cause) = try XCTUnwrap(events.get().first) else {
            return XCTFail("expected throwError(.unknown), got \(events.get())")
        }
        XCTAssertEqual(message, "boom")
        XCTAssertNil(underlying)
        XCTAssertTrue(cause is AWSCognitoIdentityProvider.InternalErrorException, "\(String(describing: cause))")
    }

    /// The resolver carries the cause to the error state
    ///
    /// - Given: a deletion in progress
    /// - When:
    ///    - `throwError` arrives with an engine error and a cause
    /// - Then:
    ///    - the state is `.error` with that engine error and that cause
    ///
    func testTheResolverCarriesTheCauseToTheErrorState() throws {
        let resolver = DeleteUserState.Resolver(signedInData: .testData)
        let cause = AWSCognitoIdentityProvider.InternalErrorException(message: "boom")

        let resolution = resolver.resolve(
            oldState: .deletingUser,
            byApplying: DeleteUserEvent(eventType: .throwError(cause.engineError, cause: cause))
        )

        guard case .error(.unknown(let message, _), let carried) = resolution.newState else {
            return XCTFail("expected .error(.unknown), got \(resolution.newState)")
        }
        XCTAssertEqual(message, "boom")
        XCTAssertTrue(carried is AWSCognitoIdentityProvider.InternalErrorException, "\(String(describing: carried))")
    }
}
