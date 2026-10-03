//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's less-travelled branches: refresh for every payload kind, a guest refresh, the sign-out and deletion decisions at states
/// Cognito rarely produces, the confirm dispatch for the restart and already-signed-in states, and the
/// configure bound.
final class LiveEngineBranchTests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness.cognito.assertConsumed()
        harness = nil
        super.tearDown()
    }

    // MARK: Refresh by kind

    /// A guest payload refreshes its AWS credentials for the same identity, with no user pool call.
    ///
    /// - Given: a guest payload for an identity
    /// - When:
    ///    - it is refreshed
    /// - Then:
    ///    - the only call is `GetCredentialsForIdentity` for that identity, with no logins
    ///    - the payload is still a guest of that identity, with the new credentials
    ///
    func testAGuestPayloadRefreshesItsCredentials() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool(identityId: "us-east-1:guest", version: 1)
        let guest = try await engine.fetchGuestCredentials(current: nil)
        harness.cognito.clearCalls()
        harness.scriptIdentityPool(identityId: "us-east-1:guest", version: 2)

        let refreshed = try await engine.refresh(guest)

        XCTAssertEqual(harness.cognito.operations, ["GetCredentialsForIdentity"])
        let input = try XCTUnwrap(harness.cognito.inputs("GetCredentialsForIdentity", as: GetCredentialsForIdentityInput.self).first)
        XCTAssertEqual(input.identityId, "us-east-1:guest")
        XCTAssertEqual(input.logins ?? [:], [:])
        XCTAssertEqual(try engine.describe(refreshed).kind, .guest)
        XCTAssertEqual(try engine.describe(refreshed).identityId, "us-east-1:guest")
        XCTAssertEqual(try engine.awsCredentials(in: refreshed)?.accessKeyId, "AKID-v2")
    }

    /// An unforced refresh of a payload whose user pool tokens are still valid refreshes only its AWS
    /// credentials, as the plugin's unforced fetch does; a forced one refreshes the tokens too.
    ///
    /// - Given: alice's signed-in payload with valid tokens and expired AWS credentials
    /// - When:
    ///    - it is refreshed unforced, then forced
    /// - Then:
    ///    - unforced, the only call is `GetCredentialsForIdentity`, and the tokens are unchanged
    ///    - forced, `GetTokensFromRefreshToken` comes first, then `GetCredentialsForIdentity`
    ///
    func testAnUnforcedRefreshSparesValidUserPoolTokens() async throws {
        let engine = try harness.engine()
        let payload = try await Self.withExpiredAWSCredentials(harness.signedInPayload(on: engine))
        harness.cognito.clearCalls()
        harness.scriptIdentityPool(version: 2)
        harness.scriptRefresh(version: 2)

        let unforced = try await engine.refresh(payload, force: false)

        XCTAssertEqual(harness.cognito.operations, ["GetCredentialsForIdentity"])
        XCTAssertEqual(try engine.userPoolTokens(in: unforced)?.refreshToken, "refresh-alice-v1")
        XCTAssertEqual(try engine.awsCredentials(in: unforced)?.accessKeyId, "AKID-v2")

        harness.cognito.clearCalls()
        let forced = try await engine.refresh(payload, force: true)

        XCTAssertEqual(harness.cognito.operations, ["GetTokensFromRefreshToken", "GetCredentialsForIdentity"])
        XCTAssertEqual(try engine.userPoolTokens(in: forced)?.refreshToken, "refresh-alice-v2")
    }

    /// `payload` with its AWS credentials already expired.
    static func withExpiredAWSCredentials(_ payload: Data) throws -> Data {
        guard case .userPoolAndIdentityPool(let signedIn, let identityId, let aws) = try AmplifyCredentials.decoded(payload) else {
            throw FixtureError(description: "expected user pool and identity pool credentials")
        }
        let expired = EngineAWSCredentials(
            accessKeyId: aws.accessKeyId,
            secretAccessKey: aws.secretAccessKey,
            sessionToken: aws.sessionToken,
            expiration: Date(timeIntervalSince1970: 1_000_000_000)
        )
        return try CredentialSlot.encode(.userPoolAndIdentityPool(signedInData: signedIn, identityID: identityId, credentials: expired))
    }

    /// A federated payload refreshes through the identity pool with its federated token, keeping its
    /// identity.
    ///
    /// - Given: the frozen federated payload fixture
    /// - When:
    ///    - it is refreshed
    /// - Then:
    ///    - the only call is `GetCredentialsForIdentity`, for its identity, with its token as the login
    ///    - the payload is still federated, with the same identity and the new credentials
    ///
    func testAFederatedPayloadRefreshesThroughTheIdentityPool() async throws {
        let engine = try harness.engine()
        let payload = try EnginePayloadFixtures.data("identityPoolWithFederation")
        let identityId = try XCTUnwrap(engine.describe(payload).identityId)
        harness.scriptIdentityPool(identityId: identityId, version: 2)

        let refreshed = try await engine.refresh(payload)

        XCTAssertEqual(harness.cognito.operations, ["GetCredentialsForIdentity"])
        let input = try XCTUnwrap(harness.cognito.inputs("GetCredentialsForIdentity", as: GetCredentialsForIdentityInput.self).last)
        XCTAssertEqual(input.identityId, identityId)
        guard case .identityPoolWithFederation(let federated, _, _) = try AmplifyCredentials.decoded(payload) else {
            return XCTFail("the fixture should be federated")
        }
        XCTAssertEqual(input.logins?.count, 1)
        XCTAssertTrue(input.logins?.values.contains(federated.token) == true, "the federated token is the login")
        XCTAssertEqual(try engine.describe(refreshed).kind, .federated)
        XCTAssertEqual(try engine.describe(refreshed).identityId, identityId)
        XCTAssertEqual(try engine.awsCredentials(in: refreshed)?.accessKeyId, "AKID-v2")
    }

    /// With no identity pool configured, a refresh returns the refreshed user pool tokens. (The engine ends
    /// this refresh `.sessionEstablished`; the `.sessionError(.noIdentityPool)` arm is exercised directly in
    /// `testTheNoIdentityPoolArmReturnsTheRefreshedCredentials`.)
    ///
    /// - Given: a user-pool-only configuration and a signed-in payload
    /// - When:
    ///    - it is refreshed
    /// - Then:
    ///    - the only call is `GetTokensFromRefreshToken`, and the payload holds the new tokens
    ///
    func testAUserPoolOnlyRefreshReturnsTheNewTokens() async throws {
        harness = LiveEngineHarness(configuration: ClientFixtures.userPoolOnlyConfiguration)
        let engine = try harness.engine()
        harness.scriptSRP()
        guard case .done(let payload) = try await engine.signIn(.srp(), current: nil) else {
            return XCTFail("the scripted sign-in did not finish")
        }
        harness.cognito.clearCalls()
        harness.scriptRefresh(version: 2)

        let refreshed = try await engine.refresh(payload)

        XCTAssertEqual(harness.cognito.operations, ["GetTokensFromRefreshToken"])
        XCTAssertEqual(try engine.userPoolTokens(in: refreshed)?.refreshToken, "refresh-alice-v2")
        XCTAssertEqual(try engine.describe(refreshed).kind, .userPoolOnly)
    }

    /// The `.sessionError(.noIdentityPool)` arm returns the refreshed credentials: the slot's when the engine
    /// wrote it, else the error's.
    ///
    /// - Given: the arm's error, over an operation whose slot was written and over one whose slot was not
    /// - When:
    ///    - each is classified
    /// - Then:
    ///    - the first returns the slot's credentials, the second the error's; neither throws
    ///
    func testTheNoIdentityPoolArmReturnsTheRefreshedCredentials() throws {
        let resources = try harness.resources()
        let fromError = try AmplifyCredentials.decoded(EnginePayloadFixtures.data("userPoolOnly"))
        let failure = AuthorizationError.sessionError(.noIdentityPool, fromError)

        let written = try resources.makeOperation(seed: EnginePayloadFixtures.data("userPoolOnly"))
        let stored = AmplifyCredentials.userPoolOnly(signedInData: SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: EngineUserPoolTokens(
                idToken: LiveEngineFixtures.jwt("alice", use: "id", version: 2),
                accessToken: LiveEngineFixtures.jwt("alice", use: "access", version: 2),
                refreshToken: "refresh-alice-v2",
                expiration: Date(timeIntervalSince1970: 4_000_000_000)
            )
        ))
        written.slot.write(stored)
        XCTAssertEqual(try AmplifyCredentials.decoded(LiveSessionEngine.refreshResult(for: failure, in: written)), stored)

        let untouched = try resources.makeOperation(seed: EnginePayloadFixtures.data("userPoolOnly"))
        XCTAssertEqual(try AmplifyCredentials.decoded(LiveSessionEngine.refreshResult(for: failure, in: untouched)), fromError)
    }

    /// Guest credentials fetched with a guest `current` refresh that guest, and the produced payload is
    /// what the plugin's credential store reads.
    ///
    /// - Given: a guest payload
    /// - When:
    ///    - guest credentials are fetched with it as `current`
    /// - Then:
    ///    - the only call is `GetCredentialsForIdentity` for its identity; the payload is the same guest with
    ///      new credentials
    ///    - stored as it is under the plugin's session account, the plugin's `AWSCognitoAuthCredentialStore`
    ///      reads it unchanged
    ///
    func testAGuestFetchWithAGuestRefreshesIt() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool(identityId: "us-east-1:guest", version: 1)
        let guest = try await engine.fetchGuestCredentials(current: nil)
        harness.cognito.clearCalls()
        harness.scriptIdentityPool(identityId: "us-east-1:guest", version: 2)

        let refreshed = try await engine.fetchGuestCredentials(current: guest)

        XCTAssertEqual(harness.cognito.operations, ["GetCredentialsForIdentity"])
        XCTAssertEqual(try engine.describe(refreshed).identityId, "us-east-1:guest")
        XCTAssertEqual(try engine.awsCredentials(in: refreshed)?.accessKeyId, "AKID-v2")
        let read = try harness.retrievedByThePlugin(refreshed)
        XCTAssertNotEqual(read, .noCredentials, "the plugin should read a refreshed guest payload as signed in")
        XCTAssertEqual(read, try AmplifyCredentials.decoded(refreshed))
    }

    /// A refresh that fails after the engine stored credentials hands those credentials back with the
    /// failure, decided from the slot, not from the error: with
    /// refresh-token rotation the engine stores the rotated tokens before it reports an identity pool
    /// failure.
    ///
    /// - Given: an operation whose slot the engine wrote with new credentials, and one whose slot it did not
    /// - When:
    ///    - each is classified for the same identity pool service failure
    /// - Then:
    ///    - the first throws `refreshedThenFailed` with the slot's credentials and the mapped failure
    ///    - the second throws the plain mapped failure
    ///
    func testARefreshFailureAfterTheSlotWasWrittenCarriesThePayload() throws {
        let resources = try harness.resources()
        let old = try AmplifyCredentials.decoded(EnginePayloadFixtures.data("userPoolAndIdentityPool"))
        let failure = AuthorizationError.sessionError(.service(AWSCognitoIdentity.InternalErrorException(message: "boom")), old)

        let written = try resources.makeOperation(seed: EnginePayloadFixtures.data("userPoolAndIdentityPool"))
        let rotated = try AmplifyCredentials.decoded(EnginePayloadFixtures.data("userPoolOnly"))
        written.slot.write(rotated)
        XCTAssertThrowsError(try LiveSessionEngine.refreshResult(for: failure, in: written)) { error in
            guard case SessionEngineError.refreshedThenFailed(let payload, .service) = error else {
                return XCTFail("expected refreshedThenFailed, got \(error)")
            }
            XCTAssertEqual(try? AmplifyCredentials.decoded(payload), rotated)
        }

        let untouched = try resources.makeOperation(seed: EnginePayloadFixtures.data("userPoolAndIdentityPool"))
        XCTAssertThrowsError(try LiveSessionEngine.refreshResult(for: failure, in: untouched)) { error in
            guard case SessionEngineError.service = error else {
                return XCTFail("expected a plain service failure, got \(error)")
            }
        }
    }

    /// The user pool tokens' own expiry, at a given instant: the core's clock, with the engine's buffer.
    ///
    /// - Given: the frozen user-pool-only payload, and the guest one
    /// - When:
    ///    - `userPoolTokensNeedRefresh` is asked well before, just outside and just inside the two-minute buffer
    /// - Then:
    ///    - the tokens need a refresh only inside the buffer; a payload without tokens never does
    ///
    func testUserPoolTokensNeedRefreshUsesTheGivenInstant() throws {
        let engine = try harness.engine()
        let payload = try EnginePayloadFixtures.data("userPoolOnly")
        let expiry = EnginePayloadFixtures.expiry

        XCTAssertFalse(try engine.userPoolTokensNeedRefresh(payload, at: expiry.addingTimeInterval(-86_400)))
        XCTAssertFalse(try engine.userPoolTokensNeedRefresh(payload, at: expiry.addingTimeInterval(-121)))
        XCTAssertTrue(try engine.userPoolTokensNeedRefresh(payload, at: expiry.addingTimeInterval(-119)))
        XCTAssertFalse(try engine.userPoolTokensNeedRefresh(EnginePayloadFixtures.data("identityPoolOnly"), at: expiry))
    }

    /// A user-pool-only payload with valid tokens does not need a refresh, even with an identity pool
    /// configured: only its tokens count, as in the plugin's `areValid()` (a refresh storm otherwise).
    ///
    /// - Given: the frozen user-pool-only payload, well before its expiry
    /// - When:
    ///    - `needsRefresh` is asked by an engine with both pools
    /// - Then:
    ///    - it says no
    ///
    func testAValidUserPoolOnlyPayloadNeedsNoRefresh() throws {
        let payload = try EnginePayloadFixtures.data("userPoolOnly")
        let early = EnginePayloadFixtures.expiry.addingTimeInterval(-86_400)

        XCTAssertFalse(try harness.engine().needsRefresh(payload, at: early))
    }

    // MARK: Sign-out decision

    /// A sign-out that fails in the engine is thrown, so the core reports it as the revoke failure.
    ///
    /// - Given: the state a failed engine sign-out ends in (`.signingOut(.error(.localSignOut))`)
    /// - When:
    ///    - the sign-out's result is read at it, and at a signed-out state
    /// - Then:
    ///    - the error is thrown as a mapped `AuthClientError`; a signed-out state is its outcome; any other
    ///      state keeps waiting
    ///
    func testASignOutErrorStateIsThrown() throws {
        let failed = AuthState.configured(.signingOut(.error(.localSignOut)), .configured, .notStarted)
        XCTAssertThrowsError(try LiveSessionEngine.signOutResult(at: failed)) { error in
            // `SignOutError.localSignOut` is the engine's `.unknown`.
            XCTAssertEqual((error as? AuthClientError)?.kind, .unknown)
        }
        let signedOut = AuthState.configured(.signedOut(SignedOutData()), .configured, .notStarted)
        XCTAssertEqual(try LiveSessionEngine.signOutResult(at: signedOut), .complete)
        let running = AuthState.configured(.signingOut(.revokingToken), .configured, .notStarted)
        XCTAssertNil(try LiveSessionEngine.signOutResult(at: running))
    }

    // MARK: Delete user

    /// A deletion that succeeded is reported as succeeded even if the engine's own sign-out after it fails;
    /// one that never reached the sign-out is a failure.
    ///
    /// - Given: the states of a deletion that reached its sign-out and then errored, and of one that errored
    ///   before
    /// - When:
    ///    - each is followed with `DeletionProgress`
    /// - Then:
    ///    - the first ends as deleted; the second throws the mapped error
    ///
    func testADeletionIsJudgedByReachingItsSignOut() throws {
        let signedIn = SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: EngineUserPoolTokens(
                idToken: LiveEngineFixtures.jwt("alice", use: "id"),
                accessToken: LiveEngineFixtures.jwt("alice", use: "access"),
                refreshToken: "refresh",
                expiration: Date(timeIntervalSince1970: 4_000_000_000)
            )
        )
        func state(_ deletion: DeleteUserState) -> AuthState {
            .configured(.deletingUser(signedIn, deletion), .deletingUser, .notStarted)
        }
        let failure = EngineAuthError.service("boom", "s")

        var afterDeletion = DeletionProgress()
        XCTAssertFalse(try afterDeletion.advance(state(.deletingUser)))
        XCTAssertFalse(try afterDeletion.advance(state(.signingOut(.notStarted))))
        XCTAssertTrue(try afterDeletion.advance(state(.error(failure))), "the user was deleted")
        XCTAssertTrue(afterDeletion.deleted)

        var beforeDeletion = DeletionProgress()
        XCTAssertFalse(try beforeDeletion.advance(state(.deletingUser)))
        XCTAssertThrowsError(try beforeDeletion.advance(state(.error(failure)))) { error in
            XCTAssertEqual((error as? AuthClientError)?.kind, .service(nil))
        }
    }

    /// A payload with no user pool tokens has no user to delete: `notSignedIn`, with no call.
    ///
    /// - Given: a guest payload
    /// - When:
    ///    - its user is deleted
    /// - Then:
    ///    - it throws `notSignedIn`, and nothing was called
    ///
    func testDeletingWithoutAUserIsNotSignedIn() async throws {
        let engine = try harness.engine()

        await assertThrowsAsync({ try await engine.deleteUser(EnginePayloadFixtures.data("identityPoolOnly")) }) { error in
            guard case .notSignedIn = authError(error) else {
                return XCTFail("expected notSignedIn, got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// Deleting a hosted-UI session's user skips the hosted-UI logout page, as sign-out does: its sign-out goes straight to the global sign-out.
    ///
    /// - Given: a signed-in payload whose sign-in method is the hosted UI (not a private session)
    /// - When:
    ///    - its user is deleted
    /// - Then:
    ///    - `DeleteUser`, then `GlobalSignOut`, were called: the hosted-UI step (which this configuration,
    ///      with no OAuth settings, could not even start) was skipped
    ///
    func testDeletingAHostedUISessionsUserSkipsTheHostedUI() async throws {
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload(on: engine)
        let hostedUI = try LiveEngineSessionTests.withHostedUISignInMethod(payload)
        harness.cognito.clearCalls()
        harness.cognito.once("DeleteUser") { (_: DeleteUserInput) in DeleteUserOutput() }
        harness.scriptSignOut()

        try await engine.deleteUser(hostedUI)

        XCTAssertEqual(Array(harness.cognito.operations.prefix(2)), ["DeleteUser", "GlobalSignOut"])
    }

    // MARK: Confirm dispatch

    /// The retained states the plugin refuses to confirm, and the one it confirms by sending nothing.
    ///
    /// - Given: a machine whose SRP step or migrate-auth step failed, and one already signed in
    /// - When:
    ///    - an answer is dispatched for each
    /// - Then:
    ///    - the two failed steps throw the plugin's "Cannot use confirmSignIn in the current state"
    ///      `invalidState` and drop the attempt; the signed-in machine sends nothing
    ///
    func testTheConfirmDispatchForRestartAndSignedInStates() throws {
        let data = ConfirmSignInEventData(answer: "x", attributes: [:], metadata: nil, friendlyDeviceName: nil, presentationAnchor: nil)
        let signInData = SignInEventData(username: "alice", password: "p", signInMethod: .apiBased(.userSRP))
        let failure = SignInError.unknown(message: "failed")
        let restartStates: [SignInState] = [
            .signingInWithSRP(.error(failure), signInData),
            .signingInViaMigrateAuth(.error(failure), signInData)
        ]
        for signInState in restartStates {
            let state = AuthState.configured(.signingIn(signInState), .configured, .notStarted)
            XCTAssertThrowsError(try LiveSignInSteps.confirmation(for: state, answering: data)) { error in
                guard let failure = error as? SignInStepFailure,
                      case .invalidState(let description, _, _) = failure.error as? AuthClientError else {
                    return XCTFail("expected a dropping invalidState, got \(error)")
                }
                XCTAssertFalse(failure.keepsAttempt)
                XCTAssertTrue(description.hasPrefix("Cannot use confirmSignIn in the current state."), description)
            }
        }
        let signedIn = SignedInData(
            signedInDate: Date(),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: EngineUserPoolTokens(idToken: "i", accessToken: "a", refreshToken: "r", expiration: Date())
        )
        let state = AuthState.configured(.signedIn(signedIn), .configured, .notStarted)
        guard case .alreadySignedIn = try LiveSignInSteps.confirmation(for: state, answering: data) else {
            return XCTFail("a signed-in machine should confirm by sending nothing")
        }
    }

    // MARK: The configure bound

    /// `EngineOperation.bounded` turns a body that never finishes into `unknown`, and passes a result through.
    ///
    /// - Given: a body that sleeps far past a short bound, and one that returns at once
    /// - When:
    ///    - each runs under the bound
    /// - Then:
    ///    - the first throws `unknown` naming what did not finish; the second returns its value
    ///
    func testTheBoundTurnsAHangIntoAnError() async throws {
        await assertThrowsAsync({
            try await EngineOperation.bounded(1_000_000, "Configuring the test") {
                try await Task.sleep(nanoseconds: 60_000_000_000)
                return 1
            }
        }) { error in
            guard case .unknown(let description, _, _) = authError(error) else {
                return XCTFail("expected unknown, got \(error)")
            }
            XCTAssertTrue(description.contains("Configuring the test"), description)
        }
        let value = try await EngineOperation.bounded(60_000_000_000, "Returning") { 7 }
        XCTAssertEqual(value, 7)
    }
}
