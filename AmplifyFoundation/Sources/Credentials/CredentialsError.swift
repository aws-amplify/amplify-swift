//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Why a credentials provider could not vend credentials.
///
/// This exists so a consumer can decide what to do without string-matching. A client
/// buffering records has to choose between discarding them and retrying the flush, and
/// those are opposite actions: discarding a retryable failure loses data, retrying a
/// permanent one buffers forever. `disposition` encodes that choice once, here, rather
/// than leaving each consumer to re-derive it.
///
/// May gain cases in a minor release: read `disposition` rather than switching over the cases, or include
/// `@unknown default` when you do.
@_spi(AmplifyExperimental)
public enum CredentialsError {

    /// Resolution was attempted against a signed-out session.
    ///
    /// Never a silent fallback to unauthenticated credentials: a consumer wired to an
    /// authenticated identity receiving guest credentials is a privilege bug wearing
    /// graceful degradation as a disguise.
    case notSignedIn(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// The refresh token expired or was revoked, so this session needs a fresh sign-in.
    /// Other sessions are unaffected.
    case sessionExpired(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Secure storage could not be read or written. See `StorageUnavailableReason`.
    /// This is emphatically *not* "signed out".
    case storageUnavailable(StorageUnavailableReason, ErrorDescription, RecoverySuggestion, Error? = nil)

    /// The provider cannot vend this kind of credential in its current configuration — for example
    /// AWS credentials from a session that has no identity pool. A misconfiguration, not a user state.
    case notConfigured(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// A failure that does not fall into the categories above.
    case unknown(ErrorDescription, RecoverySuggestion, Error? = nil)
}

@_spi(AmplifyExperimental)
public extension CredentialsError {

    /// What a consumer holding buffered work should do about this failure.
    ///
    /// Read this instead of switching on the case, so that adding a case later does not
    /// silently change behaviour at every call site.
    ///
    /// May gain cases in a minor release: include `@unknown default` when you switch over it.
    enum Disposition: Sendable, Equatable {

        /// Permanent for this session. Discard buffered work; do not retry.
        case discard

        /// Recoverable by re-authentication. Retain buffered work and retry after sign-in.
        case retryAfterReauthentication

        /// Transient. Retry with backoff.
        case retryWithBackoff

        /// Permanent, and a misconfiguration rather than a user state. Surface it; do not
        /// bury it in a retry loop.
        case failLoudly
    }

    /// The action this failure calls for.
    var disposition: Disposition {
        switch self {
        case .notSignedIn:
            return .discard
        case .sessionExpired:
            return .retryAfterReauthentication
        case .storageUnavailable(let reason, _, _, _):
            switch reason {
            case .locked, .interrupted:
                return .retryWithBackoff
            case .denied:
                return .failLoudly
            }
        case .notConfigured:
            return .failLoudly
        case .unknown:
            // Deliberately the cautious choice: an unrecognised failure must not cause
            // buffered work to be thrown away.
            return .retryWithBackoff
        }
    }
}

@_spi(AmplifyExperimental)
extension CredentialsError: AmplifyError {

    public var errorDescription: ErrorDescription {
        switch self {
        case .notSignedIn(let description, _, _),
             .sessionExpired(let description, _, _),
             .notConfigured(let description, _, _),
             .unknown(let description, _, _):
            return description
        case .storageUnavailable(_, let description, _, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .notSignedIn(_, let suggestion, _),
             .sessionExpired(_, let suggestion, _),
             .notConfigured(_, let suggestion, _),
             .unknown(_, let suggestion, _):
            return suggestion
        case .storageUnavailable(_, _, let suggestion, _):
            return suggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .notSignedIn(_, _, let error),
             .sessionExpired(_, _, let error),
             .notConfigured(_, _, let error),
             .unknown(_, _, let error):
            return error
        case .storageUnavailable(_, _, _, let error):
            return error
        }
    }

    public init(
        errorDescription: ErrorDescription,
        recoverySuggestion: RecoverySuggestion,
        error: Error?
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, recoverySuggestion, error)
        }
    }
}
