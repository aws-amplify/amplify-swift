//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

typealias AuthorizationStateSequence = StateSequence<AuthorizationState, AuthorizationEvent>

extension AuthorizationStateSequence {
    init(
        oldState: MyState,
        event: MyEvent,
        expected: MyState
    ) {
        self.resolver = AuthorizationState.Resolver().logging().eraseToAnyResolver()
        self.oldState = oldState
        self.event = event
        self.expected = expected
    }
}
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AuthorizationStateResolverTests: XCTestCase, @unchecked Sendable {

    func testValidAuthorizationStateSequences() throws {
        let authorizationError = AuthorizationError.configuration(message: "someError")
        let testCredentials = AmplifyCredentials.testData
        let validSequences: [AuthorizationStateSequence] = [
            AuthorizationStateSequence(
                oldState: .notConfigured,
                event: AuthorizationEvent(eventType: .configure),
                expected: .configured
            ),
            AuthorizationStateSequence(
                oldState: .notConfigured,
                event: AuthorizationEvent(
                                        eventType: .cachedCredentialsAvailable(testCredentials)),
                expected: .sessionEstablished(testCredentials)
            ),
            AuthorizationStateSequence(
                oldState: .notConfigured,
                event: AuthorizationEvent(
                                        eventType: .throwError(authorizationError)),
                expected: .error(authorizationError)
            )

        ]

        for sequence in validSequences {
            sequence.assertResolvesToExpected()
        }
    }

    func testInvalidAuthorizationStateSequences() throws {
        let authorizationError = AuthorizationError.configuration(message: "someError")
        let invalidSequences: [AuthorizationStateSequence] = [

            AuthorizationStateSequence(
                oldState: .notConfigured,
                event: AuthorizationEvent(eventType: .throwError(authorizationError)),
                expected: .configured
            ),
            AuthorizationStateSequence(
                oldState: .configured,
                event: AuthorizationEvent(eventType: .throwError(authorizationError)),
                expected: .notConfigured
            )
        ]

        for sequence in invalidSequences {
            sequence.assertNotResolvesToExpected()
        }
    }

    // MARK: - A refresh that fails after its user-pool step keeps the refreshed tokens

    /// The refreshed tokens are kept and stored when fetching AWS credentials fails, once
    ///
    /// - Given: A refresh past its user-pool step, fetching AWS credentials for the existing identity
    /// - When:
    ///    - The AWS credentials fetch fails, and the same failure arrives again
    /// - Then:
    ///    - The state holds the refreshed tokens with the existing identity ID and AWS credentials
    ///    - One `PersistRefreshedUserPoolTokens` stores them and then runs `InformSessionError`
    ///    - The repeated failure stores nothing, and the reported error ends in the refreshed credentials
    ///
    func testRefreshKeepsRefreshedTokensWhenAWSCredentialsFetchFails() throws {
        let refreshed = SignedInData.testData
        let awsCredentials = EngineAWSCredentials.testData
        let failure = FetchAuthSessionEvent(eventType: .throwError(.service(RefreshTestError())))
        let resolver = AuthorizationState.Resolver()

        let first = resolver.resolve(
            oldState: .refreshingSession(
                existingCredentials: .userPoolAndIdentityPool(
                    signedInData: .expiredTestData,
                    identityID: "identityId",
                    credentials: awsCredentials
                ),
                .refreshingAWSCredentialsWithUserPoolTokens(refreshed, "identityId")
            ),
            byApplying: failure
        )

        let expected = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: refreshed,
            identityID: "identityId",
            credentials: awsCredentials
        )
        guard case .refreshingSession(let kept, .error) = first.newState else {
            return XCTFail("Unexpected state \(first.newState)")
        }
        XCTAssertEqual(kept, expected)
        XCTAssertEqual(first.actions.count, 1)
        let persist = try XCTUnwrap(first.actions.first as? PersistRefreshedUserPoolTokens)
        XCTAssertEqual(persist.credentials, expected)
        XCTAssertEqual(persist.followUp.map(\.identifier), ["InformSessionError"])

        let again = resolver.resolve(oldState: first.newState, byApplying: failure)
        XCTAssertTrue(again.actions.isEmpty, "Re-entry resolved to \(again.actions)")

        let reported = resolver.resolve(
            oldState: first.newState,
            byApplying: AuthorizationEvent(eventType: .receivedSessionError(.service(RefreshTestError())))
        )
        guard case .error(.sessionError(_, let credentials)) = reported.newState else {
            return XCTFail("Unexpected state \(reported.newState)")
        }
        XCTAssertEqual(credentials, expected)
    }

    /// The refreshed tokens are kept and stored when fetching the identity ID fails, once
    ///
    /// - Given: A refresh past its user-pool step, fetching an identity ID for user-pool-only credentials
    /// - When:
    ///    - The identity ID fetch fails, and the same failure arrives again
    /// - Then:
    ///    - The state holds user-pool-only credentials with the refreshed tokens, stored by one action
    ///    - The repeated failure stores nothing
    ///
    func testRefreshKeepsRefreshedTokensWhenIdentityIdFetchFails() throws {
        let refreshed = SignedInData.testData
        let failure = FetchAuthSessionEvent(eventType: .throwError(.service(RefreshTestError())))
        let resolver = AuthorizationState.Resolver()

        let first = resolver.resolve(
            oldState: .refreshingSession(
                existingCredentials: .userPoolOnly(signedInData: .expiredTestData),
                .fetchingAuthSessionWithUserPool(.fetchingIdentityID(UnAuthLoginsMapProvider()), refreshed)
            ),
            byApplying: failure
        )

        guard case .refreshingSession(let kept, .fetchingAuthSessionWithUserPool(.error, _)) = first.newState else {
            return XCTFail("Unexpected state \(first.newState)")
        }
        XCTAssertEqual(kept, .userPoolOnly(signedInData: refreshed))
        let persist = try XCTUnwrap(first.actions.first as? PersistRefreshedUserPoolTokens)
        XCTAssertEqual(persist.credentials, .userPoolOnly(signedInData: refreshed))
        XCTAssertEqual(persist.followUp.map(\.identifier), ["InformSessionError"])

        let again = resolver.resolve(oldState: first.newState, byApplying: failure)
        XCTAssertFalse(again.actions.contains { $0 is PersistRefreshedUserPoolTokens })
    }

    /// An authorization error from the identity step stores the refreshed tokens, then is reported once
    ///
    /// - Given: A refresh past its user-pool step, fetching an identity ID
    /// - When:
    ///    - `AuthorizationEvent.throwError` arrives, and then again (the persist action re-sends it)
    /// - Then:
    ///    - The first keeps the refresh going with the refreshed credentials, stored before the re-send
    ///    - The second resolves to `.error` with no actions
    ///
    func testRefreshKeepsRefreshedTokensWhenIdentityStepThrowsAuthorizationError() throws {
        let refreshed = SignedInData.testData
        let failure = AuthorizationEvent(eventType: .throwError(.configuration(message: "no identity client")))
        let resolver = AuthorizationState.Resolver()

        let first = resolver.resolve(
            oldState: .refreshingSession(
                existingCredentials: .userPoolOnly(signedInData: .expiredTestData),
                .fetchingAuthSessionWithUserPool(.fetchingIdentityID(UnAuthLoginsMapProvider()), refreshed)
            ),
            byApplying: failure
        )

        guard case .refreshingSession(
            let kept,
            .fetchingAuthSessionWithUserPool(.fetchingIdentityID, _)
        ) = first.newState else {
            return XCTFail("Unexpected state \(first.newState)")
        }
        XCTAssertEqual(kept, .userPoolOnly(signedInData: refreshed))
        XCTAssertEqual(first.actions.count, 1)
        let persist = try XCTUnwrap(first.actions.first as? PersistRefreshedUserPoolTokens)
        XCTAssertEqual(persist.followUp.map(\.identifier), ["ReportAuthorizationError"])

        let again = resolver.resolve(oldState: first.newState, byApplying: failure)
        guard case .error(.configuration) = again.newState else {
            return XCTFail("Unexpected state \(again.newState)")
        }
        XCTAssertTrue(again.actions.isEmpty)
    }

    /// Nothing is kept or stored when the user-pool data did not change
    ///
    /// - Given: A refresh of AWS credentials only, whose user-pool data equals the existing one
    /// - When:
    ///    - The AWS credentials fetch fails
    /// - Then:
    ///    - The existing credentials stay, and only `InformSessionError` runs
    ///
    func testRefreshOfAWSCredentialsOnlyStoresNothingWhenItFails() {
        let signedInData = SignedInData.testData
        let existing = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: signedInData,
            identityID: "identityId",
            credentials: .expiredTestData
        )

        let resolution = AuthorizationState.Resolver().resolve(
            oldState: .refreshingSession(
                existingCredentials: existing,
                .refreshingAWSCredentialsWithUserPoolTokens(signedInData, "identityId")
            ),
            byApplying: FetchAuthSessionEvent(eventType: .throwError(.service(RefreshTestError())))
        )

        guard case .refreshingSession(let kept, .error) = resolution.newState else {
            return XCTFail("Unexpected state \(resolution.newState)")
        }
        XCTAssertEqual(kept, existing)
        XCTAssertEqual(resolution.actions.map(\.identifier), ["InformSessionError"])
    }

}

private struct RefreshTestError: Error { }
