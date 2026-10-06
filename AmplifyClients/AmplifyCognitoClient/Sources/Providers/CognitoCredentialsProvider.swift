//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

/// Vends one session's AWS credentials to any client in the family.
///
/// - **Bound to its session for life.** Every copy resolves the same session; there is no ambient
///   lookup.
/// - **Fails rather than falls back.** A signed-out session throws `notSignedIn`. It never quietly
///   returns guest credentials.
/// - **Never serves a stale snapshot.** It holds no credentials: every call resolves through the live
///   session, refreshing it if needed, and concurrent calls on one session share one refresh.
/// - **Keeps its session alive**, exactly as holding an `AmplifyCognitoClient` does.
///
/// Failures are `CredentialsError`, whose `disposition` tells a consumer holding buffered work what to
/// do. `CancellationError` passes through unwrapped.
@_spi(AmplifyExperimental)
public struct CognitoCredentialsProvider: AWSCredentialsProvider, Sendable {

    /// Strong: a provider keeps its session alive.
    let core: SessionCore

    init(core: SessionCore) {
        self.core = core
    }

    /// The session this provider resolves.
    public var sessionId: SessionID {
        core.sessionId
    }

    /// The session's current AWS credentials, refreshed first if they need it.
    ///
    /// A guest session vends its guest credentials and a federated session its federated ones; a
    /// signed-out session never becomes a guest here.
    ///
    /// - Throws: `CredentialsError`, whose `disposition` says what to do with buffered work:
    ///   - `.notConfigured` if the configuration has no identity pool, or the session is signed in to the
    ///     user pool only;
    ///   - `.notSignedIn` for a signed-out session, and while a sign-in on it waits on a challenge;
    ///   - `.sessionExpired` if the refresh token (or a federated session's provider token) is dead;
    ///   - `.storageUnavailable` if secure storage could not be read or written;
    ///   - `.unknown` for anything else, such as a refresh that failed on the network, or a saved record
    ///     this version cannot read.
    ///
    ///   `CancellationError`, unwrapped, if the calling task is cancelled; a refresh it started carries on
    ///   for the session.
    public func resolve() async throws -> any AWSCredentials {
        do {
            return try await core.resolveAWSCredentials()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw CredentialsError(authClientError: error)
        }
    }
}

extension CredentialsError {

    /// Maps a session failure onto the provider contract's error set.
    ///
    /// `notSignedIn`, `sessionExpired` and `storageUnavailable` keep their meaning; a `CredentialsError`
    /// (such as `notConfigured`) passes through; anything else is `unknown`, whose disposition is to
    /// retry with backoff — the cautious default, which never costs a consumer its buffered data.
    init(authClientError error: Error) {
        switch error {
        case let error as CredentialsError:
            self = error
        case let error as AuthClientError:
            switch error {
            case .notSignedIn(let description, let suggestion, _):
                self = .notSignedIn(description, suggestion, error)
            case .sessionExpired(let description, let suggestion, _):
                self = .sessionExpired(description, suggestion, error)
            case .storageUnavailable(let reason, let description, let suggestion, _):
                self = .storageUnavailable(reason, description, suggestion, error)
            case .configuration, .invalidSessionID, .challengeExpired, .browserBusy,
                 .sessionConfigurationMismatch, .validation, .service, .notAuthorized, .invalidState,
                 .userCancelled, .webAuthnCeremonyFailed, .unexpectedIdentity, .unknown:
                self = .unknown(error.errorDescription, error.recoverySuggestion, error)
            }
        default:
            self = .unknown("The session could not provide credentials.", "Retry the operation.", error)
        }
    }
}
