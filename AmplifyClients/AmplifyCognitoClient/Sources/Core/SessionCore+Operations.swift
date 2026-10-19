//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

/// The two routes the signed-in and signed-out operations take to the engine. Sign-in
/// steps (`autoSignIn`) take the sign-in route in `SessionCore+SignIn`, and federation its own in
/// `SessionCore+Federation`.
///
/// Neither route writes the session record or takes `signInLock`, so neither disturbs a pending sign-in on
/// the same session, and neither is serialized behind one.
extension SessionCore {

    /// Runs a user-pool operation that acts on a username rather than on the session's user: sign-up and
    /// password reset. It needs a user pool, and nothing else: as with the plugin, it runs whether or not
    /// the session is signed in, and reads no storage.
    ///
    /// - Parameter operation: What the operation does, for the errors ("sign up").
    /// - Throws: `configuration` without a user pool; otherwise the engine's failure, mapped.
    nonisolated func userPoolOperation<T: Sendable>(
        _ operation: String,
        _ body: @Sendable (any SessionEngine) async throws -> T
    ) async throws -> T {
        try requireUserPool(for: operation)
        do {
            return try await body(engine)
        } catch {
            throw Self.operationFailure(error, operation: operation)
        }
    }

    /// Runs an operation on the session's signed-in user with the session's credentials payload: restored,
    /// and refreshed first through the session's single refresh flight if its credentials need it (never a
    /// second refresh). With an identity pool that includes its AWS credentials, refreshed with the tokens as the
    /// plugin does, so an identity pool failure fails the operation even while the access token is valid, except for a
    /// session still waiting for its first identity (`isIdentityPending`), whose token is used without it
    /// (`freshPayload(for:)`). The engine reads the access token from the payload.
    ///
    /// - Parameter operation: What the operation does, for the errors ("fetch the user attributes").
    /// - Throws: `configuration` without a user pool; `notSignedIn` for a signed-out, guest or federated
    ///   session, and while a sign-in waits on a challenge; `sessionExpired` when the refresh token is dead;
    ///   `storageUnavailable` if storage could not be read; otherwise the engine's failure, mapped.
    nonisolated func signedInOperation<T: Sendable>(
        _ operation: String,
        _ body: @Sendable (any SessionEngine, Data) async throws -> T
    ) async throws -> T {
        try requireUserPool(for: operation)
        let payload: Data
        do {
            try await requireUserPoolUser()
            payload = try await freshPayload(for: .accessToken)
            guard try engine.checkedAccessToken(in: payload) != nil else {
                throw Self.notSignedIn(sessionId)
            }
        } catch let error as CredentialsError {
            throw Self.authClientError(from: error)
        }
        do {
            return try await body(engine, payload)
        } catch {
            throw Self.operationFailure(error, operation: operation)
        }
    }

    /// The preamble of an operation on the session's signed-in user, before anything is refreshed: restores the
    /// session, and refuses with `notSignedIn` a federated session (no user pool user, and nothing to refresh for
    /// one) and one whose sign-in waits on a challenge (a pending sign-in is not a signed-in user).
    nonisolated func requireUserPoolUser() async throws {
        _ = try await restoredSnapshot()
        switch await currentState {
        case .federated, .awaitingChallenge:
            throw Self.notSignedIn(sessionId)
        default:
            return
        }
    }

    /// Maps an operation's engine failure onto the public errors, per the seam's error contract. Such an
    /// operation never refreshes, so `refreshTokenInvalid` is not expected here; if one arrived it would be
    /// `unknown`, not `sessionExpired`: only the refresh path, which also marks the session expired, may say
    /// that.
    static func operationFailure(_ error: Error, operation: String) -> Error {
        switch error {
        case is AuthClientError, is CancellationError:
            return error
        case let error as CredentialsError:
            return authClientError(from: error)
        case SessionEngineError.service(let error):
            return error
        case SessionEngineError.notSignedIn:
            return AuthClientError.notSignedIn("The session is not signed in.", "Sign in first.", error)
        default:
            if let network = AuthClientError.networkFailure(error) {
                return network
            }
            return AuthClientError.unknown("The client could not \(operation).", "Retry the operation.", error)
        }
    }
}
