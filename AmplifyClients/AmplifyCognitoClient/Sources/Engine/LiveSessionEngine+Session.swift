//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth

/// The session operations: each is one fresh operation seeded with the payload
/// it was handed, ported from the plugin's task layer. They are `nonisolated` and touch none of the actor's
/// state, so they never wait for, or disturb, a pending sign-in.
extension LiveSessionEngine {

    // MARK: Refresh

    /// One refresh of *this* payload: never coalesced, cached or skipped (single-flight is the core's). The
    /// event is chosen by the payload's kind, as `FetchAuthSessionOperationHelper.refreshIfRequired` chooses
    /// it, with the caller's `force`: unforced, the engine refreshes the user pool tokens only if they expire,
    /// and otherwise only the AWS credentials (`InitializeRefreshSession`).
    nonisolated func refresh(_ payload: Data, force: Bool) async throws -> Data {
        let credentials = try Self.credentials(in: payload)
        let event: StateMachineEvent
        switch credentials {
        case .userPoolOnly, .userPoolAndIdentityPool:
            try requireUserPool()
            event = AuthorizationEvent(eventType: .refreshSession(force))
        case .identityPoolOnly:
            try requireIdentityPool()
            event = AuthorizationEvent(eventType: .refreshSession(force))
        case .identityPoolWithFederation(let federatedToken, let identityId, _):
            try requireIdentityPool()
            event = AuthorizationEvent(eventType: .startFederationToIdentityPool(federatedToken, identityId))
        case .noCredentials:
            throw SessionEngineError.notSignedIn
        }
        let operation = try resources.makeOperation(seed: payload)
        try await operation.configure(resources.authConfiguration)
        await operation.send(event)
        return try await operation.firstState { state in
            guard case .configured(_, let authorization, _) = state else {
                return nil
            }
            switch authorization {
            case .sessionEstablished(let established):
                return try operation.payload(establishing: established)
            case .error(let error):
                if case .identityPoolWithFederation = credentials {
                    return try Self.federatedRefreshResult(for: error, in: operation)
                }
                return try Self.refreshResult(for: error, in: operation)
            default:
                return nil
            }
        }
    }

    /// The classification of a failed refresh.
    ///
    /// | Engine terminal | Seam |
    /// |---|---|
    /// | `.sessionExpired` (`NotAuthorizedException`) | `refreshTokenInvalid` |
    /// | `.sessionError(.service(RefreshTokenReuseException), _)` | `refreshTokenReused` |
    /// | `.sessionError(.noIdentityPool, credentials)` | not an error: the refreshed user pool credentials |
    /// | anything else | `service(mapped)` |
    /// | any error, with the operation's slot written | `refreshedThenFailed(payload: slot, error: row above)` |
    ///
    /// The last row is decided from the slot, never from the error's credentials: the engine stores
    /// rotated user pool tokens before it reports an identity pool failure (`PersistRefreshedUserPoolTokens`),
    /// and whatever it stored is what the next refresh must use.
    static func refreshResult(for error: AuthorizationError, in operation: EngineOperation) throws -> Data {
        let failure: SessionEngineError
        switch error {
        case .sessionExpired:
            failure = .refreshTokenInvalid
        case .sessionError(.service(let serviceError), _) where serviceError is RefreshTokenReuseException:
            failure = .refreshTokenReused
        case .sessionError(.noIdentityPool, let credentials):
            // Parity with `sessionResultWithError`'s `noIdentityPool` branch: a missing identity pool does
            // not fail the user pool tokens, which the engine has refreshed and stored.
            if case .written(let written) = operation.slot.current {
                return try CredentialSlot.encode(written)
            }
            return try CredentialSlot.encode(credentials)
        default:
            failure = .service(AuthClientError(engine: error.engineError))
        }
        if case .written(let stored) = try operation.slot.outcome() {
            throw SessionEngineError.refreshedThenFailed(payload: stored, error: failure)
        }
        throw failure
    }

    // MARK: Guest credentials

    /// Unauthenticated identity pool credentials. A guest `current` is refreshed, as the plugin's fetch
    /// refreshes an established guest session; anything else starts from no credentials.
    ///
    /// - Throws: `SessionEngineError.notSignedIn` when the identity pool has guest access off (`notAuthorized`
    ///   or `noCredentialsToRefresh`): the plugin's `makeSessionWithNoGuestAccess`.
    nonisolated func fetchGuestCredentials(current: Data?) async throws -> Data {
        try requireIdentityPool()
        let seed = try current.flatMap(Self.guestSeed)
        let operation = try resources.makeOperation(seed: seed)
        try await operation.configure(resources.authConfiguration)
        let event = seed == nil
            ? AuthorizationEvent(eventType: .fetchUnAuthSession)
            : AuthorizationEvent(eventType: .refreshSession(true))
        await operation.send(event)
        return try await operation.firstState { state in
            guard case .configured(_, let authorization, _) = state else {
                return nil
            }
            switch authorization {
            case .sessionEstablished(let established):
                return try operation.payload(establishing: established)
            case .error(.sessionError(.notAuthorized, _)), .error(.sessionError(.noCredentialsToRefresh, _)):
                throw SessionEngineError.notSignedIn
            case .error(let error):
                throw SessionEngineError.service(AuthClientError(engine: error.engineError))
            default:
                return nil
            }
        }
    }

    // MARK: Sign-out

    /// Revokes the payload's tokens, globally first when asked (`AWSAuthSignOutTask`, `Actions/SignOut/*`).
    /// The slot's `.cleared` is discarded: the core clears the record.
    ///
    /// - A guest, federated or empty payload has nothing to revoke: the outcome is complete with no call.
    ///   (The engine's `signOutGuest` path would only clear the operation's slot, which is discarded.)
    /// - The hosted-UI sign-out runs only for `.present`, after a sign-in that shared the browser's cookies
    ///   (`LiveSessionEngine+WebUI.swift`); otherwise it is skipped and the revoke still runs.
    /// - After a failed global sign-out the engine does not call `RevokeToken`, and the outcome keeps the
    ///   engine's placeholder revoke error beside the real global failure, as the plugin's result does.
    nonisolated func revoke(_ payload: Data, global: Bool, hostedUI: EngineHostedUISignOut) async throws -> EngineSignOutOutcome {
        switch try Self.credentials(in: payload) {
        case .noCredentials, .identityPoolOnly, .identityPoolWithFederation:
            return .complete
        case .userPoolOnly, .userPoolAndIdentityPool:
            try requireUserPool()
        }
        if case .present(let anchor) = hostedUI, try signOutPresentsBrowser(payload) {
            return try await revokePresenting(payload, global: global, in: anchor)
        }
        return try await revokeSkippingHostedUI(payload, global: global)
    }

    /// The sign-out with the hosted UI's step skipped.
    ///
    /// A caller already cancelled sends nothing: it throws `CancellationError`, and nothing is revoked.
    /// Otherwise the sign-out runs in a task of its own, which the caller's cancellation does not reach, as a
    /// presenting sign-out does (`revokePresenting`): the machine's actions run in detached tasks, so a
    /// `GlobalSignOut` or `RevokeToken` once sent reaches Cognito whatever the caller does, and this returns what it
    /// really did rather than a `CancellationError` while Cognito revokes the tokens.
    nonisolated func revokeSkippingHostedUI(_ payload: Data, global: Bool) async throws -> EngineSignOutOutcome {
        try Task.checkCancellation()
        let resources = resources
        let flow = Task { () -> EngineSignOutOutcome in
            let operation = try resources.makeOperation(seed: payload)
            try await operation.configure(resources.authConfiguration)
            await operation.send(AuthenticationEvent(eventType: .signOutRequested(SignOutEventData(
                globalSignOut: global,
                skipHostedUISignOut: true
            ))))
            return try await operation.firstState(Self.signOutResult)
        }
        return try await flow.value
    }

    /// A sign-out's result at `state`: the outcome once signed out, a thrown failure if the sign-out itself
    /// failed (the core still clears locally), or `nil` while it runs.
    static func signOutResult(at state: AuthState) throws -> EngineSignOutOutcome? {
        guard case .configured(let authentication, _, _) = state else {
            return nil
        }
        switch authentication {
        case .signedOut(let signedOut):
            return outcome(of: signedOut)
        case .signingOut(.error(let error)):
            throw AuthClientError(engine: error.engineError)
        default:
            return nil
        }
    }

    /// The failures a sign-out reports. After a failed global sign-out the revoke failure is the engine's
    /// placeholder (`BuildRevokeTokenError`, `.service` with empty texts), kept as the plugin keeps it.
    /// The hosted-UI failure is one the engine continued past (`ShowHostedUISignOut` sends a non-hosted-UI
    /// error on to the revoke).
    static func outcome(of signedOut: SignedOutData) -> EngineSignOutOutcome {
        EngineSignOutOutcome(
            revokeFailure: signedOut.revokeTokenError,
            globalSignOutFailure: signedOut.globalSignOutError,
            hostedUIFailure: signedOut.hostedUIError
        )
    }

    // MARK: Delete user

    /// Deletes the payload's user (`AWSAuthDeleteUserTask.deleteUser`). The machine's own sign-out after the
    /// deletion is discarded: the core purges the record. It skips the hosted-UI step, as `revoke` does.
    ///
    /// It subscribes to the machine before sending the event, as the plugin's task does, so it sees every
    /// state the deletion passes through: whether Cognito deleted the user is read from the deletion having
    /// reached its sign-out, never inferred from a terminal state alone (1b, item 6).
    ///
    /// - Throws: the mapped failure; `.service(.userNotFound, …)` when Cognito no longer knows the user;
    ///   `notSignedIn` for a payload with no user pool tokens.
    nonisolated func deleteUser(_ payload: Data) async throws {
        try requireUserPool()
        guard let accessToken = try Self.credentials(in: payload).userPoolTokens?.accessToken else {
            throw AuthClientError.notSignedIn(
                "There is no user signed in to delete",
                "Call signIn to sign in a user, then deleteUser."
            )
        }
        let operation = try resources.makeOperation(seed: payload)
        try await operation.configure(resources.authConfiguration)
        var progress = DeletionProgress()
        try await operation.firstState(
            after: DeleteUserEvent(eventType: .deleteUser(accessToken, skipHostedUISignOut: true))
        ) { state in
            try progress.advance(state) ? () : nil
        }
    }
}

/// Where a deletion is, from the states its machine passes through.
struct DeletionProgress {

    /// Whether Cognito deleted the user: the deletion reached its sign-out.
    private(set) var deleted = false

    /// `true` once the deletion is over; throws if Cognito did not delete the user.
    ///
    /// A failure after the user was deleted (the engine's own sign-out, which the core discards anyway) is
    /// not a failed deletion.
    mutating func advance(_ state: AuthState) throws -> Bool {
        guard case .configured(.deletingUser(_, let deletion), _, _) = state else {
            return false
        }
        switch deletion {
        case .signingOut:
            deleted = true
            return false
        case .userDeleted:
            return true
        case .error(let error):
            if deleted {
                return true
            }
            throw AuthClientError(engine: error)
        case .notStarted, .deletingUser:
            return false
        }
    }
}
