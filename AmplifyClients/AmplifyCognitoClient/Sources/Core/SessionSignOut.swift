//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

/// Revokes, then clears locally, keeping the row: the sign-out both a live session and the static
/// `signOutStoredSession` perform. Run it while holding the record's gate.
///
/// **It never signs out a different user.** A sign-out has a window — the revoke is a network call —
/// in which another process can refresh the session or sign a different user in to the same session ID.
/// The store's own sign-out removes only the credentials it read and reports `.superseded` otherwise.
/// This procedure re-reads whenever the credentials moved, and:
/// - if the record still holds **the same user** (a refresh by another writer), it revokes the new
///   credentials too and tries again, at most `maximumAttempts` times;
/// - if it holds **a different user**, it leaves them signed in and reports `.superseded`: the caller
///   asked to sign out a session that now holds someone else.
///
/// A failed revoke still clears locally, as the plugin does, and is reported as partial: the refresh
/// token stays valid server-side until it expires. So is a failed global sign-out: the user's other
/// sessions stay signed in.
struct SessionSignOut: Sendable {

    enum Outcome: Sendable {
        /// The session held no credentials, so nothing was revoked or cleared.
        case nothingToSignOut
        /// The credentials are gone locally. `server` holds the first server-side failure of each kind.
        case signedOut(server: EngineSignOutOutcome)
        /// The record now holds a different user, who was left signed in.
        case superseded
        /// The same user's credentials kept changing, and every attempt lost its race. The session is
        /// still signed in locally, with credentials that may already be revoked.
        case contended(server: EngineSignOutOutcome)

        /// The server-side failures the sign-out collected, if any.
        var server: EngineSignOutOutcome {
            switch self {
            case .signedOut(let server), .contended(let server):
                return server
            case .nothingToSignOut, .superseded:
                return .complete
            }
        }

        var removedCredentials: Bool {
            if case .signedOut = self {
                return true
            }
            return false
        }

        /// Whether the session was signed out — its credentials removed, or it held none — as opposed to
        /// left signed in because another writer got there first.
        var endedSession: Bool {
            switch self {
            case .nothingToSignOut, .signedOut:
                return true
            case .superseded, .contended:
                return false
            }
        }

        /// The public result. Never throws: a sign-out that could not finish is `.failed`, and the session is
        /// still signed in on this device.
        ///
        /// - `.superseded` is `.failed(.invalidState)`: another sign-in replaced the session, and that user stays
        ///   signed in.
        /// - `.contended` is `.failed(.storageUnavailable(.interrupted))`, carrying the first server-side failure,
        ///   if any, as its underlying error.
        func result() -> AuthClientSignOutResult {
            switch self {
            case .nothingToSignOut:
                return .complete
            case .signedOut(let server):
                return server.signedOutResult()
            case .superseded:
                return .failed(SessionSignOut.supersededError())
            case .contended(let server):
                return .failed(.storageUnavailable(
                    .interrupted,
                    "The session's saved record kept changing during sign-out, so it is still signed in on this device.",
                    "Retry the sign-out.",
                    server.firstError
                ))
            }
        }
    }

    static let maximumAttempts = 3

    /// What a failed copy revoke logs: no identifiers.
    static let copyRevokeFailedWarning =
        "A copy of the session under a previous configuration could not be revoked. It is deleted anyway; its refresh token stays valid until it expires."

    let sessionId: SessionID
    let store: SessionRecordIO
    /// Who a credentials payload belongs to, when the record's own metadata does not say.
    let describe: @Sendable (Data) -> CredentialSummary?
    /// Whether two payloads hold the same credentials, however they are encoded (`SessionEngine.sameCredentials`):
    /// the Auth plugin saving `.default`'s credentials again in other bytes during the revoke has not moved them.
    var sameCredentials: @Sendable (Data, Data) -> Bool = CredentialSlot.sameCredentials
    /// One revoke attempt. `firstAttempt` is `true` for the first only: a sign-out shows the hosted UI's
    /// logout page on its first attempt at most, and its retries never do.
    let revoke: @Sendable (_ payload: Data, _ firstAttempt: Bool) async throws -> EngineSignOutOutcome
    /// Revokes a copy the sweep will delete that holds a refresh token the sign-out's revoke does not reach
    /// (`SessionRecordStore.copiesToRevoke`). Best effort: a failure is logged, and the sweep goes ahead.
    var revokeCopy: (@Sendable (_ payload: Data) async throws -> EngineSignOutOutcome)?

    private enum Held {
        case nothing
        case unreadable
        case credentials(Data, CredentialSummary)
    }

    /// - Throws: `AuthClientError.storageUnavailable` if storage could not be read or written. A failed
    ///   revoke does not throw; it is reported in the outcome. A revoke that throws `CancellationError` before any
    ///   attempt has revoked (after one has, it is a failed revoke and the record is cleared),
    ///   `AuthClientError.userCancelled` (the user closed the hosted UI's logout page), or a `SignOutRefusal`
    ///   (no hosted UI to sign out of), rethrows it before anything is cleared, so the session stays signed in,
    ///   as the plugin's does. The caller maps every throw to `.failed` with `failure(_:)`.
    func run() async throws -> Outcome {
        var target: (payload: Data, principal: CredentialSummary)
        switch try await held(store.read(sessionId)) {
        case .nothing:
            return .nothingToSignOut
        case .unreadable:
            // Nothing this build can read, so nothing to revoke. The store replaces it with a
            // signed-out row, so no unreadable credentials outlive sign-out.
            switch try await store.signOut(sessionId) {
            case .signedOut, .noRecord:
                return .nothingToSignOut
            case .superseded:
                return .superseded
            }
        case .credentials(let payload, let principal):
            target = (payload, principal)
        }

        var server = EngineSignOutOutcome.complete
        // Whether an attempt has already returned its outcome: the tokens it held are revoked, so the record must
        // not be kept whatever a later attempt does.
        var revokedOnce = false
        var revokedCopies = false
        for attempt in 1 ... Self.maximumAttempts {
            do {
                try await server.merge(revoke(target.payload, attempt == 1))
                revokedOnce = true
            } catch is CancellationError where revokedOnce {
                // A retry, cancelled with its caller (a cancelled task's revoke never reaches Cognito), after an
                // earlier attempt revoked. Keeping the record would keep revoked tokens: count it as a failed revoke
                // of the newer credentials, and go on to clear.
                server.merge(EngineSignOutOutcome(revokeError: Self.revokeFailure(CancellationError())))
            } catch is CancellationError {
                // The caller gave up, and nothing was revoked (a presenting sign-out that went on revoking returns
                // its outcome instead, `SessionCore.afterInterruptedLogout`); that is not a failed revoke. Clear
                // nothing and report cancellation.
                throw CancellationError()
            } catch let error as AuthClientError where error.isUserCancelled && !revokedOnce {
                // The user closed the logout page: they chose not to sign out. Clear nothing. (Only a first attempt
                // shows the page; after a revoke this is a failed revoke like any other, and the record is cleared.)
                throw error
            } catch let refusal as SignOutRefusal where !revokedOnce {
                // The hosted UI's sign-out could not run or complete, before anything was revoked: the plugin's
                // `.failed`, with the user still signed in. Clear nothing.
                throw refusal
            } catch {
                server.merge(EngineSignOutOutcome(revokeError: Self.revokeFailure(error)))
            }

            // The revoke took a network round trip: check the record still holds what was revoked.
            switch try await held(store.read(sessionId)) {
            case .nothing:
                return .signedOut(server: server)
            case .unreadable:
                return .superseded
            case .credentials(let payload, let principal):
                if payload != target.payload {
                    guard !sameCredentials(payload, target.payload) else {
                        // The same credentials saved again in other bytes (the Auth plugin re-encoding `.default`'s
                        // record): already revoked. Clear them as they are stored now.
                        target = (payload, target.principal)
                        break
                    }
                    // The credentials moved during the revoke. Revoke the new ones too only if they are
                    // provably the same principal's.
                    guard principal.isSamePrincipal(as: target.principal) else {
                        return .superseded
                    }
                    target = (payload, principal)
                    continue
                }
            }

            if !revokedCopies, let revokeCopy {
                // Before the clear, whose sweep deletes them: a copy rotated under an old configuration holds a
                // token this revoke did not reach. Best effort, as the sweep is.
                revokedCopies = true
                let payload = target.payload
                let copies = (try? await store.perform { try $0.copiesToRevoke(of: sessionId, revoking: payload) }) ?? []
                for copy in copies {
                    let revoked: EngineSignOutOutcome?
                    do {
                        revoked = try await revokeCopy(copy)
                    } catch {
                        revoked = nil
                    }
                    if revoked?.revokeError != nil || revoked == nil {
                        ClientLog.logger(ClientLog.sessionSignOut).warn(Self.copyRevokeFailedWarning)
                    }
                }
            }

            switch try await store.signOut(sessionId, removing: target.payload) {
            case .signedOut, .noRecord:
                return .signedOut(server: server)
            case .superseded:
                // Another writer replaced the credentials between the check and the clear.
                switch try await held(store.read(sessionId)) {
                case .nothing:
                    return .signedOut(server: server)
                case .credentials(let payload, let principal) where principal.isSamePrincipal(as: target.principal):
                    target = (payload, principal)
                case .credentials, .unreadable:
                    return .superseded
                }
            }
        }
        return .contended(server: server)
    }

    private func held(_ result: SessionRecordStore.ReadResult) -> Held {
        switch result {
        case .absent:
            return .nothing
        case .unsupportedSchema, .corrupt:
            return .unreadable
        case .record(let stored):
            let record = stored.record
            guard let credentials = record.credentials, record.kind != .signedOut else {
                return .nothing
            }
            let described = record.userId == nil ? describe(credentials) : nil
            return .credentials(credentials, CredentialSummary(
                kind: record.kind,
                username: record.username ?? described?.username,
                userId: record.userId ?? described?.userId,
                identityId: described?.identityId
            ))
        }
    }

    /// The `.failed` result's error for a sign-out that threw before it cleared anything, so the session is
    /// still signed in: a `CancellationError` before any revoke is `.unknown`, verbatim.
    static func failure(_ error: Error) -> AuthClientError {
        switch error {
        case is CancellationError:
            return cancelledError()
        case let refusal as SignOutRefusal:
            return refusal.error
        case let error as AuthClientError:
            return error
        case SessionEngineError.service(let error):
            return error
        default:
            return .unknown(
                "The sign-out failed before it cleared the session, so the session is still signed in.",
                "Retry the sign-out.",
                error
            )
        }
    }

    /// The task was cancelled before anything was revoked.
    static func cancelledError() -> AuthClientError {
        .unknown(
            "The sign-out was cancelled before anything was revoked; the session is still signed in.",
            "Retry the sign-out.",
            CancellationError()
        )
    }

    /// Another sign-in replaced the session while it was signing out.
    static func supersededError() -> AuthClientError {
        .invalidState(
            "Another sign-in replaced this session while it was signing out; that user is still signed in.",
            "Check the session's state, then sign out again if needed."
        )
    }

    static func revokeFailure(_ error: Error) -> AuthClientError {
        switch error {
        case let error as AuthClientError:
            return error
        case SessionEngineError.service(let error):
            return error
        default:
            return .unknown(
                "The session's tokens could not be revoked, so its refresh token stays valid until it expires.",
                "The session was signed out on this device. Retry later to revoke it.",
                error
            )
        }
    }
}

/// A first sign-out attempt that stopped before revoking anything, so the user stays signed in: the plugin's
/// `.failed` for a hosted-UI sign-out whose page could not be shown or completed: no hosted UI or sign-out redirect
/// URI, the browser busy, the window gone, or the browser step failing. `SessionSignOut.run()` rethrows
/// it, unlike a failed revoke, which it reports and clears past.
struct SignOutRefusal: Error, Sendable {
    let error: AuthClientError
}
