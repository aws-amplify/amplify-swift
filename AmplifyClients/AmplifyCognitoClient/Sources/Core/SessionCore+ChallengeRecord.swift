//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// The session's challenge record (`ChallengeRecord`): the engine's pending sign-in, saved so it survives
/// the app being closed, and resumed by the next restore.
///
/// **The record exists exactly while the engine holds an attempt it can resume.** The engine is the source of truth,
/// as it is for `pendingChallenge`:
///
/// | Event | Record |
/// |---|---|
/// | a sign-in step stops on a challenge (the first one, or the next after an answer) | written, replacing any |
/// | a wrong answer, which keeps the attempt | kept as it was |
/// | the sign-in completes | deleted, in the commit, under the gate |
/// | it fails for good (`challengeExpired`, "restart", any failure that drops the attempt) | deleted |
/// | a new `signIn`, `autoSignIn` or hosted-UI sign-in supersedes it | deleted before the new step starts |
/// | sign-out, purge, user deletion | deleted by the store (`SessionRecordStore.signOut`, `purge`) |
///
/// Every write runs under the record's gate and checks the sign-in epoch there, as a sign-in's commit does: a
/// sign-out, purge or deletion moves the epoch under the gate, so a step that finishes after one never writes the
/// record back. A delete checks the epoch without the gate (`deleteChallengeRecord(epoch:)` says why).
///
/// **Best effort.** A failed write or delete is logged (`SessionRecordStore.ChallengeLog`) and never fails the sign-in:
/// the challenge stays in memory, as it always did, and a record left behind is deleted by the next restore.
extension SessionCore {

    // MARK: Sign-in steps

    /// Saves the engine's pending attempt as the challenge record, unless the sign-in epoch moved from `epoch`. An
    /// attempt with no saved form (`confirmSignUp`, `resetPassword`) deletes the record instead, so an older one does
    /// not resurface.
    nonisolated func saveChallengeRecord(epoch: UInt64) async {
        let state = await engine.pendingChallengeState
        let createdAt = now()
        do {
            try await withRecord { [self] store in
                guard await signInEpoch == epoch else {
                    return
                }
                guard let state else {
                    try await store.deleteChallenge(sessionId)
                    return
                }
                do {
                    try await store.writeChallenge(ChallengeRecord(createdAt: createdAt, state: state), for: sessionId)
                } catch {
                    // The previous step's record must not be resumed in this one's place: best effort, it goes.
                    try? await store.deleteChallenge(sessionId)
                    throw error
                }
            }
        } catch {
            SessionRecordStore.challengeLogger.warn(
                state == nil ? SessionRecordStore.ChallengeLog.deleteFailed : SessionRecordStore.ChallengeLog.writeFailed
            )
        }
    }

    /// Deletes the challenge record of a sign-in that has ended, unless the sign-in epoch moved from `epoch`: whatever
    /// moved it deleted the record, and a newer sign-in's must stay.
    ///
    /// **Not under the record's gate**, unlike a write. A sign-out, purge or deletion holds the gate while it cancels
    /// the session's sign-in, and a step that fails meanwhile must be able to return without waiting for it (a
    /// cancel never waits for the step it ends). A delete can skip the gate: the only other writers are those same
    /// endings, which only delete, and a newer sign-in's write cannot land between this check and the delete,
    /// because every sign-in step runs under the session's `signInLock`, which this one's caller holds. The call
    /// still goes through the record's I/O queue.
    nonisolated func deleteChallengeRecord(epoch: UInt64) async {
        guard await signInEpoch == epoch else {
            return
        }
        await deleteChallengeRecord(in: SessionRecordIO(store: store, queue: gate.ioQueue))
    }

    /// `deleteChallengeRecord` for a caller that already holds the gate: the commit of a completed sign-in.
    nonisolated func deleteChallengeRecord(in store: SessionRecordIO) async {
        do {
            try await store.deleteChallenge(sessionId)
        } catch {
            SessionRecordStore.challengeLogger.warn(SessionRecordStore.ChallengeLog.deleteFailed)
        }
    }

    // MARK: Restore

    /// The challenge a restore reports: the engine's pending one, or else the one the session's challenge record
    /// resumes. Runs under the record's gate, with `loaded` the record the restore read.
    ///
    /// A record is resumed only over a session that can be signing in: signed out (or absent), or a guest. Beside a
    /// signed-in or federated record it is a leftover (its delete failed after the sign-in ended; `signIn` refuses a
    /// signed-in session), and is deleted, best effort: it is read only to see whether one is there, and a failed read
    /// is ignored, so an unreadable leftover never makes a signed-in session unavailable. One past its ceiling, which Cognito can no longer answer, one this build cannot
    /// resume, and corrupt bytes are deleted too. A newer schema's record is left for its writer. None is read over a
    /// session record that could not be read.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the record of a session that can be signing in could not be
    ///   read: the restore fails, and a retry may succeed. Unreadable is not absent.
    nonisolated func pendingOrResumedChallenge(_ loaded: SessionSnapshot, store: SessionRecordIO) async throws -> AuthClientSignInStep? {
        if let pending = await engine.pendingChallenge {
            return pending
        }
        switch loaded.state(engine: engine, challenge: nil) {
        case .signedOut, .guest:
            break
        case .signedIn, .federated:
            // Best effort, and only if one is there: a restore of a signed-in session writes nothing otherwise.
            if let leftover = try? await store.readChallenge(sessionId), leftover != .absent {
                await discardChallengeRecord(in: store)
            }
            return nil
        case .unavailable, .failed, .awaitingChallenge:
            return nil
        }
        let record: ChallengeRecord
        switch try await store.readChallenge(sessionId) {
        case .absent, .unsupportedSchema:
            return nil
        case .corrupt:
            await discardChallengeRecord(in: store)
            return nil
        case .record(let read):
            record = read
        }
        guard !record.isPastCeiling(at: now()) else {
            await discardChallengeRecord(in: store)
            return nil
        }
        if let step = await engine.resumeSignIn(from: record.state, epoch: signInEpoch) {
            return step
        }
        // Not resumed: an attempt that went live meanwhile is newer, and keeps the record; otherwise this build
        // cannot resume it.
        if let pending = await engine.pendingChallenge {
            return pending
        }
        await discardChallengeRecord(in: store)
        return nil
    }

    private nonisolated func discardChallengeRecord(in store: SessionRecordIO) async {
        do {
            try await store.deleteChallenge(sessionId)
        } catch {
            SessionRecordStore.challengeLogger.warn(SessionRecordStore.ChallengeLog.discardFailed)
        }
    }
}
