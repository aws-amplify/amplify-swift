//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// The in-memory view of a session's stored record, as last read or written.
///
/// A session answers state questions from this, not from storage: it is replaced after every read and
/// every committed write the session itself makes. A change made by another process becomes visible on
/// this session's next read.
struct SessionSnapshot: Sendable, Equatable {

    enum Source: Sendable, Equatable {
        /// Nothing is stored.
        case absent
        /// The session's own record. For `.default`, the Auth plugin's record with the sidecar's label.
        case own(SessionRecord)
        /// A record is present that this build cannot use.
        case unreadable(Unreadable)
    }

    enum Unreadable: Sendable, Equatable {
        case unsupportedSchema(version: Int)
        case corrupt
    }

    /// The version a write over the stored record must expect: a named session's generation, or `.default`'s stored
    /// bytes.
    let version: RecordVersion?
    let source: Source

    static let absent = SessionSnapshot(version: nil, source: .absent)

    init(version: RecordVersion?, source: Source) {
        self.version = version
        self.source = source
    }

    /// A named session's envelope, as just committed.
    init(_ envelope: SessionRecordEnvelope) {
        self.init(VersionedSessionRecord(envelope))
    }

    init(_ stored: VersionedSessionRecord) {
        self.init(version: stored.version, source: .own(stored.record))
    }

    init(_ result: SessionRecordStore.ReadResult) {
        switch result {
        case .absent:
            self = .absent
        case .record(let stored):
            self.init(stored)
        case .unsupportedSchema(let version):
            self.init(version: nil, source: .unreadable(.unsupportedSchema(version: version)))
        case .corrupt:
            self.init(version: nil, source: .unreadable(.corrupt))
        }
    }

    /// Reads a session's record once. Decodes and checks nothing else: not expiry, and not the network.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if storage could not be read.
    static func load(_ sessionId: SessionID, from store: SessionRecordStore) throws -> SessionSnapshot {
        try SessionSnapshot(store.read(sessionId))
    }

    /// The credentials payload, if the session holds one.
    var credentials: Data? {
        switch source {
        case .own(let record):
            return record.credentials
        case .absent, .unreadable:
            return nil
        }
    }

    /// Whether the session holds exactly `payload`'s credentials, however they are encoded
    /// (`SessionEngine.sameCredentials`).
    func holdsCredentials(_ payload: Data, engine: any SessionEngine) -> Bool {
        guard let credentials else {
            return false
        }
        return engine.sameCredentials(credentials, payload)
    }

    /// The session's own record, if it has one.
    var ownRecord: SessionRecord? {
        guard case .own(let record) = source else {
            return nil
        }
        return record
    }

    /// Who and what the stored credentials are: from the record's listing metadata when it is complete,
    /// otherwise from the engine, which reads the payload without the network. `nil` if the session
    /// holds no credentials.
    func summary(engine: any SessionEngine) throws -> CredentialSummary? {
        switch source {
        case .absent, .unreadable:
            return nil
        case .own(let record):
            guard let credentials = record.credentials, record.kind != .signedOut else {
                return nil
            }
            let fromRecord = CredentialSummary(kind: record.kind, username: record.username, userId: record.userId)
            if record.kind == .guest || fromRecord.user != nil {
                return fromRecord
            }
            let described = try engine.describe(credentials)
            // A federated record names no user, so it always gets here: its identity is the payload's.
            return CredentialSummary(
                kind: record.kind,
                username: record.username ?? described.username,
                userId: record.userId ?? described.userId,
                identityId: described.identityId
            )
        }
    }

    /// The state this snapshot projects to.
    ///
    /// A pending challenge overlays every state except a storage failure or an unrecoverable one. A
    /// refresh that proved the refresh token dead does not change the state: the session stays
    /// `.signedIn(user)`, so an app knows which user to re-authenticate, and its operations throw
    /// `sessionExpired`.
    func state(engine: any SessionEngine, challenge: AuthClientSignInStep?) -> AuthSessionState {
        let base = baseState(engine: engine)
        switch base {
        case .unavailable, .failed:
            return base
        case .signedIn, .federated, .signedOut, .guest, .awaitingChallenge:
            return challenge.map(AuthSessionState.awaitingChallenge) ?? base
        }
    }

    private func baseState(engine: any SessionEngine) -> AuthSessionState {
        switch source {
        case .absent:
            return .signedOut
        case .unreadable(.unsupportedSchema(let version)):
            return .failed(.unknown(
                "This session was saved by a newer version of the app (record schema \(version)) and cannot be read.",
                "Update the app. Signing this session out replaces the record."
            ))
        case .unreadable(.corrupt):
            return .failed(.unknown(
                "This session's saved record is unreadable.",
                "Sign the session out to reset it."
            ))
        case .own(let record) where record.kind == .signedOut:
            return .signedOut
        case .own(let record) where record.credentials == nil:
            return .failed(.unknown(
                "This session's saved record is inconsistent: it has kind \(record.kind) but no credentials.",
                "Sign the session out to reset it."
            ))
        case .own:
            let summary: CredentialSummary?
            do {
                summary = try self.summary(engine: engine)
            } catch {
                return .failed(.unknown(
                    "This session's saved credentials could not be read.",
                    "Sign the session out to reset it.",
                    error
                ))
            }
            guard let summary else {
                return .signedOut
            }
            return Self.state(for: summary)
        }
    }

    private static func state(for summary: CredentialSummary) -> AuthSessionState {
        switch summary.kind {
        case .signedOut:
            return .signedOut
        case .guest:
            return .guest
        case .federated:
            // A federated session is its identity, never
            // an invented user, so `isSamePrincipal` can never equate a user pool `sub` with an identity ID.
            guard let identityId = summary.identityId else {
                return .failed(.unknown(
                    "This session's saved federated credentials hold no identity ID.",
                    "Sign the session out and federate again."
                ))
            }
            return .federated(identityId: identityId)
        case .userPoolOnly, .userPoolAndIdentityPool:
            // Signed in only when the engine names a user; otherwise reported, not guessed.
            guard let user = summary.user else {
                return .failed(.unknown(
                    "This session's saved credentials do not say which user is signed in.",
                    "Sign the session out and sign in again."
                ))
            }
            return .signedIn(user)
        }
    }
}
