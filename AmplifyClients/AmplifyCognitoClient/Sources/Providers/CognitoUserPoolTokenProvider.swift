//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

/// Vends one session's user pool access token.
///
/// The same contract as `CognitoCredentialsProvider`: bound to its session for life, fails rather than
/// falls back (a signed-out or guest session throws `notSignedIn`), holds no token of its own, shares
/// the session's one refresh, and keeps its session alive. A federated session has no user pool tokens,
/// so it throws `notConfigured`. Failures are `CredentialsError`; `CancellationError` passes through
/// unwrapped.
@_spi(AmplifyExperimental)
public struct CognitoUserPoolTokenProvider: Sendable {

    /// Strong: a provider keeps its session alive.
    let core: SessionCore

    init(core: SessionCore) {
        self.core = core
    }

    /// The session this provider resolves.
    public var sessionId: SessionID {
        core.sessionId
    }

    /// A currently valid access token for the session's signed-in user, refreshed first if it needs it.
    ///
    /// - Throws: `CredentialsError`, whose `disposition` says what to do with buffered work:
    ///   - `.notConfigured` if the configuration has no user pool, or the session is federated to the
    ///     identity pool;
    ///   - `.notSignedIn` for a signed-out or guest session, and while a sign-in on it waits on a challenge;
    ///   - `.sessionExpired` if the refresh token is dead;
    ///   - `.storageUnavailable` if secure storage could not be read or written;
    ///   - `.unknown` for anything else, such as a refresh that failed on the network, or a saved record
    ///     this version cannot read.
    ///
    ///   `CancellationError`, unwrapped, if the calling task is cancelled; a refresh it started carries on
    ///   for the session.
    public func accessToken() async throws -> String {
        do {
            return try await core.accessToken()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw CredentialsError(authClientError: error)
        }
    }
}
