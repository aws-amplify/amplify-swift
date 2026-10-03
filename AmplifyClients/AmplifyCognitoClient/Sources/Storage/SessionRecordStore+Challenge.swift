//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

// The challenge record (`ChallengeRecord`): a sign-in interrupted on a challenge, saved under
// `amplify.1.<poolNamespace>.<sessionId>.challenge` so it survives the app being closed.
//
// One writer per record: the session's core, under its sign-in lock and the record's gate. No commit guard and no
// generation: the record is short-lived, and across processes (an app and its extension signing one session in at
// once) the last write wins, as limit 5 of the design already says of every record.
//
// A challenge is **never carried** to a new pool configuration (`SessionRecordStore+CopyForward.swift`): its session
// string is bound to the old configuration's app client. Sign-out and purge delete the challenge records under the
// namespaces the session's marker remembers, as they delete the session's copies there.
extension SessionRecordStore {

    /// What is stored as a session's challenge record.
    enum ChallengeRead: Equatable, Sendable {
        case absent
        case record(ChallengeRecord)
        /// Written by a newer schema: not resumed, and left for its writer.
        case unsupportedSchema(version: Int)
        /// Bytes that are not a challenge record.
        case corrupt
    }

    /// Log lines of the challenge record, one place so tests can hold them.
    enum ChallengeLog {
        static let category = ClientLog.category(ClientLog.sessionRecordStore)
        static let writeFailed =
            "The interrupted sign-in could not be saved, so it does not survive the app being closed. The sign-in itself is unaffected."
        static let deleteFailed =
            "The interrupted sign-in's saved record could not be deleted after the sign-in ended. The session's next restore deletes it."
        static let discardFailed =
            "An interrupted sign-in's saved record that cannot be resumed could not be deleted. It is ignored."
        static let sweepFailed =
            "An expired interrupted sign-in's saved record could not be deleted. The next listing tries again."
        static let rememberedDeleteFailed =
            "A signed-out session's interrupted sign-in under a previous configuration could not be deleted. It is left, and cannot be resumed once 15 minutes old."
    }

    static var challengeLogger: any Logger {
        ClientLog.logger(ClientLog.sessionRecordStore)
    }

    // MARK: Read, write, delete

    /// The session's challenge record.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if it could not be read. Never `.absent` for a failure.
    func readChallenge(_ sessionId: SessionID) throws -> ChallengeRead {
        guard let data = try fetch(challengeAccount(for: sessionId), operation: "read the interrupted sign-in record") else {
            return .absent
        }
        switch ChallengeRecord.decode(data) {
        case .record(let record):
            return .record(record)
        case .unsupportedSchema(let version):
            return .unsupportedSchema(version: version)
        case .corrupt:
            return .corrupt
        }
    }

    /// Writes the session's challenge record, replacing any.
    ///
    /// If the stored record holds the same Cognito session string, its `createdAt` is kept: the session's lifetime
    /// runs from when Cognito issued it, not from this write (a first-factor selection of `PASSWORD` moves the
    /// step under the same session, for one).
    ///
    /// The read is best effort: a record that cannot be read is replaced, with the new `createdAt`.
    ///
    /// - Returns: The record as written.
    /// - Throws: `AuthClientError.storageUnavailable` if it could not be written.
    @discardableResult
    func writeChallenge(_ record: ChallengeRecord, for sessionId: SessionID) throws -> ChallengeRecord {
        var written = record
        if case .record(let stored) = try? readChallenge(sessionId),
           let session = stored.state.session, session == record.state.session {
            written.createdAt = stored.createdAt
        }
        let data = try written.encoded()
        try performChallengeStorage("write the interrupted sign-in record") {
            try keychain.set(data, key: challengeAccount(for: sessionId))
        }
        return written
    }

    /// Deletes the session's challenge record. Deleting an absent record succeeds.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if it could not be deleted.
    func deleteChallenge(_ sessionId: SessionID) throws {
        try performChallengeStorage("delete the interrupted sign-in record") {
            try keychain.remove(challengeAccount(for: sessionId))
        }
    }

    // MARK: Previous configurations

    /// Deletes the session's challenge records under the namespaces of the copies its marker remembers, never this
    /// one's: the namespaces this app left the session under before a configuration change, and so the ones whose
    /// leftovers are this store's to sweep. A challenge is never carried, so any found there is left from before the
    /// change. The namespace the marker names, when it is not this one, is another configuration's (an uncarried
    /// change, or an extension on the old configuration), and is left alone, as its session record is. Reads the
    /// marker, so it runs before `removePreviousCopies`, which rewrites it.
    ///
    /// **Exactly when `removePreviousCopies` deletes that copy.** A marker keeps other users' copies too (each records
    /// its user, `NamespaceMarker.Copy.user`), so a copy's namespace is swept only when:
    /// - that copy's user is the reference user, the one `removePreviousCopies` uses: the user of the record being
    ///   signed out or purged, else the marker's own user for this namespace (never for a copy with no recorded user,
    ///   so bob's sign-out at B leaves alice's interrupted sign-in at A);
    /// - and the copy's session record there is still what was carried (its digest) and is not a guest's. A changed
    ///   record belongs to another writer (an extension still on that configuration), whose sign-in there this must
    ///   not end; a guest's copy is left for the same reason. A copy whose record is already gone is left too: nothing
    ///   shows the namespace is still only this session's.
    ///
    /// **Two differences from `removePreviousCopies`, and one path it does not cover:**
    /// - the namespace the marker names is excluded even if a copy names it; `removePreviousCopies` has no such check,
    ///   because it never records a copy there;
    /// - a failed delete during sign-out is logged and not retried: `removePreviousCopies` then still deletes the copy
    ///   and forgets it, so nothing sweeps that challenge record again;
    /// - a restore over a signed-out row sweeps the copies too (`readKept` → `sweepQuietly`), without this call, so the
    ///   same user's challenge records under those copies' namespaces are left.
    ///
    /// Each record left this way is dead once past the 15-minute ceiling, and holds nothing a later sign-in reads:
    /// a restore under its configuration deletes it on read, as it deletes any record past the ceiling.
    ///
    /// - Parameters:
    ///   - reference: The record being signed out, when the caller has it; otherwise this namespace's record is read.
    ///   - throwing: whether a failure throws (purge), or is logged (sign-out, which has already signed the session out
    ///     and must not fail on this).
    /// - Throws: `AuthClientError.storageUnavailable`, when `throwing`, if the marker or a record could not be read,
    ///   or a record deleted.
    func removeRememberedChallenges(of sessionId: SessionID, reference knownReference: SessionRecord? = nil, throwing: Bool = true) throws {
        let own = namespace.pools.keyComponent
        let copies: [NamespaceMarker.Copy]
        do {
            guard case .marker(let marker) = try readMarker(for: sessionId), !marker.copies.isEmpty else {
                return
            }
            let reference: SessionRecord?
            if let knownReference {
                reference = knownReference
            } else if case .record(let stored) = try read(sessionId) {
                reference = stored.record
            } else {
                reference = nil
            }
            let referenceUser = reference.flatMap(userKey) ?? (marker.poolNamespace == own ? marker.user : nil)
            guard let referenceUser else {
                return
            }
            // Never this namespace, nor the one the marker names (another configuration's), even if a copy says so.
            let excluded: Set<String> = [own, marker.poolNamespace]
            copies = marker.copies.filter { $0.user == referenceUser && !excluded.contains($0.poolNamespace) }
        } catch {
            if throwing { throw error }
            Self.challengeLogger.warn(ChallengeLog.rememberedDeleteFailed)
            return
        }
        for copy in copies {
            do {
                let recordAccount = SessionRecordKey.account(for: sessionId, namespaceComponent: copy.poolNamespace, kind: .session)
                guard let data = try fetch(recordAccount, operation: "read a session record of a previous configuration"),
                      Self.digest(data) == copy.sha256,
                      case .envelope(let stored) = SessionRecordEnvelope.decode(data),
                      stored.record.kind != .guest else {
                    continue
                }
                let account = SessionRecordKey.account(for: sessionId, namespaceComponent: copy.poolNamespace, kind: .challenge)
                try performChallengeStorage("delete an interrupted sign-in record of a previous configuration") {
                    try keychain.remove(account)
                }
            } catch {
                if throwing { throw error }
                Self.challengeLogger.warn(ChallengeLog.rememberedDeleteFailed)
            }
        }
    }

    // MARK: Sweeping

    /// Deletes this namespace's challenge records that are past the ceiling at `now`, of any session: what a
    /// listing does, so a record whose session ID the app never saved (a `.new()` session killed mid-sign-in) does
    /// not stay behind for good. Best effort: a failure is logged, and a record that changed since it was read is
    /// left (a re-read, then a delete; not atomic, as the keychain has no compare-and-delete).
    ///
    /// Corrupt and newer-schema records are left: only a session's own restore, or its sign-out or purge, deletes
    /// those.
    ///
    /// - Parameter accounts: the service's accounts, as a listing read them.
    func sweepExpiredChallenges(in accounts: [String], at now: Date) {
        let own = namespace.pools.keyComponent
        for account in Set(accounts).sorted() {
            guard let parsed = SessionRecordKey.parse(account),
                  parsed.kind == .challenge,
                  parsed.namespaceComponent == own else {
                continue
            }
            do {
                guard let data = try fetch(account, operation: "read an interrupted sign-in record"),
                      case .record(let record) = ChallengeRecord.decode(data),
                      record.isPastCeiling(at: now),
                      try fetch(account, operation: "re-read an interrupted sign-in record") == data else {
                    continue
                }
                try performChallengeStorage("delete an expired interrupted sign-in record") { try keychain.remove(account) }
            } catch {
                Self.challengeLogger.warn(ChallengeLog.sweepFailed)
            }
        }
    }

    private func performChallengeStorage<Value>(_ operation: String, _ body: () throws -> Value) throws -> Value {
        do {
            return try body()
        } catch {
            throw AuthClientError.storageUnavailable(from: error, operation: operation)
        }
    }
}
