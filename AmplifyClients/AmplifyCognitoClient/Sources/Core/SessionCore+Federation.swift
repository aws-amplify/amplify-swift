//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Federation to the identity pool.
///
/// **The states are the plugin's.** Federation starts only from a signed-out, guest or already federated
/// session (`AWSAuthFederateToIdentityPoolTask.swift:87-94`), and clearing needs a federated one
/// (`ClearFederationOperationHelper`), each refused before any network call with the plugin's strings. A
/// federated session reports `AuthSessionState.federated(identityId:)`.
///
/// **A federation commits a record, so it has sign-in's guards**: it runs under the
/// session's `signInLock`, so it never interleaves with a sign-in step; a federation queued before a
/// sign-out, purge or deletion never starts (the session-ending count); one those ran during never commits
/// (the sign-in epoch, checked under the record's gate); and its write is a compare-before-write against the
/// record version it started from. A lost race re-reads, and never overwrites a user another writer signed in.
/// The network step and the commit run in one unstructured task, so a caller's cancellation cannot drop a
/// federation Cognito completed.
///
/// **Events.** Federating sends none: no user pool user signs in (the plugin's Hub sends no `signedIn`
/// either); the state stream reports `.federated`. Clearing sends `.signedOut`, as every path that removes a
/// session's credentials does (a guest's sign-out, a purge), and the state becomes `.signedOut`.
extension SessionCore {

    /// - Throws: `configuration` without an identity pool; `invalidState` with the plugin's strings on a
    ///   session signed in to the user pool or waiting on a challenge, before any network call, or when a
    ///   user signed in to the session while it federated; `storageUnavailable`; the engine's mapped
    ///   failure (a rejected token is `notAuthorized`).
    nonisolated func federateToIdentityPool(_ request: EngineFederationRequest) async throws -> AuthClientFederateToIdentityPoolResult {
        try requireIdentityPool(for: "federate to the identity pool")
        _ = try await restoredSnapshot()
        // The refusal first, so a refused call neither queues nor reaches the network.
        _ = try await federationBase()
        let engine = engine
        let endings = await sessionEndings
        return try await signInLock.withLock { [self] in
            guard await sessionEndings == endings else {
                throw Self.federationCancelled()
            }
            return try await Task { [self] in
                // Again under the lock: a sign-in may have completed while this call queued.
                let (base, epoch) = try await federationBase()
                let payload: Data
                do {
                    payload = try await engine.federateToIdentityPool(request, current: base.credentials)
                } catch {
                    if await signInEpoch != epoch {
                        throw Self.federationCancelled()
                    }
                    throw Self.operationFailure(error, operation: "federate to the identity pool")
                }
                let (result, summary) = try Self.federationResult(payload, engine: engine)
                try await commitFederation(payload, summary: summary, base: base, epoch: epoch)
                return result
            }.value
        }
    }

    /// - Throws: `invalidState` with the plugin's strings unless the session is federated, before anything is
    ///   written, and when another writer replaced the federation meanwhile (a user signed in, the session was
    ///   signed out, or a different federated identity was stored): only the identity this call found is ever
    ///   cleared; `storageUnavailable`.
    nonisolated func clearFederationToIdentityPool() async throws {
        _ = try await restoredSnapshot()
        let identityId = try await requireFederated()
        try await withRecord { [self] store in
            var cancelled = false
            for _ in 1 ... Self.maximumRecordWriteAttempts {
                let current = try await store.load(sessionId)
                guard let payload = current.credentials, federatedSummary(of: current)?.identityId == identityId else {
                    // Since the check, another writer signed a user in, signed the session out, or stored a
                    // different federated identity: none of those is this call's to clear.
                    await apply(current, event: nil)
                    throw Self.clearingFailed()
                }
                if !cancelled {
                    // Under the gate, where a federation commit checks the epoch: one in flight never lands
                    // over the clear, and one queued never starts.
                    await cancelPendingSignIns()
                    cancelled = true
                }
                switch try await store.signOut(sessionId, removing: payload) {
                case .signedOut, .noRecord:
                    let after: SessionSnapshot
                    do {
                        after = try await store.load(sessionId)
                    } catch {
                        after = .absent
                    }
                    await apply(after, challenge: .set(nil), event: .signedOut)
                    return
                case .superseded:
                    // The credentials moved between the read and the clear. The re-read above clears them only
                    // if they are still the same identity's (another writer refreshed it).
                    continue
                }
            }
            throw Self.contended("clearing of the federation")
        }
    }

    // MARK: Commit

    /// Commits a federation's payload under the record's gate, expecting the record version it started from.
    ///
    /// When the record moved meanwhile (`.discarded`) it re-reads, then writes again over an absent, signed-out
    /// or guest record, over the same identity as ours, or over the federation this one replaces (another
    /// writer refreshed it). A user pool user, a different federated identity, or a record that cannot be read
    /// is never overwritten: it throws `invalidState` and the session reports what is stored. At most
    /// `maximumRecordWriteAttempts` writes, then `storageUnavailable(.interrupted)`.
    private nonisolated func commitFederation(
        _ payload: Data,
        summary: CredentialSummary,
        base: SessionSnapshot,
        epoch: UInt64
    ) async throws {
        let replacing = federatedSummary(of: base)
        try await withRecord { [self] store in
            guard await signInEpoch == epoch else {
                throw Self.federationCancelled()
            }
            var current = base
            for _ in 1 ... Self.maximumRecordWriteAttempts {
                let record = SessionRecord(
                    label: Self.label(keptFrom: current.ownRecord, for: summary),
                    username: summary.username,
                    userId: summary.userId,
                    kind: summary.kind,
                    credentials: payload
                )
                if case .committed(let committed) = try await store.write(record, for: sessionId, expecting: current.version) {
                    await apply(SessionSnapshot(committed), event: nil)
                    return
                }
                let reread = try await store.load(sessionId)
                guard mayReplace(reread, with: summary, replacing: replacing) else {
                    await apply(reread, event: nil)
                    throw AuthClientError.invalidState(
                        "Another sign-in or federation completed for this session while this federation was in progress",
                        "That session is still stored. Sign it out, or clear its federation, then federate again."
                    )
                }
                current = reread
            }
            throw Self.contended("federation")
        }
    }

    /// Whether a re-read record may be overwritten by the federation `ours`.
    private nonisolated func mayReplace(_ snapshot: SessionSnapshot, with ours: CredentialSummary, replacing: CredentialSummary?) -> Bool {
        if case .unreadable = snapshot.source {
            return false
        }
        let held: CredentialSummary?
        do {
            held = try snapshot.summary(engine: engine)
        } catch {
            return false
        }
        guard let held, held.kind != .signedOut, held.kind != .guest else {
            return true
        }
        // A user pool user is never replaced, even one with the same identity pool identity.
        guard held.kind == .federated else {
            return false
        }
        return held.isSamePrincipal(as: ours) || replacing.map { held.isSamePrincipal(as: $0) } == true
    }

    // MARK: State

    /// The snapshot a federation starts from and the epoch it commits under; or the plugin's refusal. One
    /// actor call, so both see the same state.
    private func federationBase() throws -> (SessionSnapshot, UInt64) {
        guard let snapshot = restoredSnapshotIfAny else {
            // `restoredSnapshot()` returned, so a snapshot is installed; nothing ever removes one.
            throw AuthClientError.unknown("The session could not be restored.", "Retry the operation.")
        }
        switch snapshot.state(engine: engine, challenge: pendingChallenge) {
        case .signedOut, .guest, .federated:
            return (snapshot, signInEpoch)
        case .signedIn, .awaitingChallenge:
            throw AuthClientError.invalidState(
                "Federation could not be completed.",
                "Operation performed is not a valid operation for the current auth state"
            )
        case .unavailable(let reason):
            throw AuthClientError.storageUnavailable(reason, "Secure storage could not be read.", "Retry later. Do not treat this as signed out.")
        case .failed(let error):
            throw error
        }
    }

    /// The identity of the federation to clear.
    private nonisolated func requireFederated() async throws -> String {
        switch await currentState ?? .signedOut {
        case .federated(let identityId):
            return identityId
        case .unavailable(let reason):
            throw AuthClientError.storageUnavailable(reason, "Secure storage could not be read.", "Retry later. Do not treat this as signed out.")
        case .signedIn, .signedOut, .guest, .awaitingChallenge, .failed:
            throw Self.clearingFailed()
        }
    }

    /// The snapshot's summary when it holds a federation, else `nil`.
    private nonisolated func federatedSummary(of snapshot: SessionSnapshot) -> CredentialSummary? {
        guard let summary = try? snapshot.summary(engine: engine), summary.kind == .federated else {
            return nil
        }
        return summary
    }

    /// The public result and the summary a federation's payload commits with.
    ///
    /// - Throws: `unknown` with the plugin's string if the payload is not a federation with an identity and
    ///   AWS credentials; nothing is committed then.
    static func federationResult(
        _ payload: Data,
        engine: any SessionEngine
    ) throws -> (AuthClientFederateToIdentityPoolResult, CredentialSummary) {
        let summary = try engine.checkedDescribe(payload)
        guard summary.kind == .federated,
              let identityId = summary.identityId,
              let credentials = try engine.checkedAWSCredentials(in: payload) else {
            throw AuthClientError.unknown(
                "Unable to parse credentials to expected output",
                "This is not expected. Retry the federation."
            )
        }
        let result = AuthClientFederateToIdentityPoolResult(
            credentials: AuthClientAWSCredentials(credentials),
            identityId: identityId
        )
        return (result, summary)
    }

    // MARK: Errors

    static func clearingFailed() -> AuthClientError {
        .invalidState(
            "Clearing of federation failed.",
            "Operation performed is not a valid operation for the current auth state"
        )
    }

    static func federationCancelled() -> AuthClientError {
        .invalidState(
            "The federation was cancelled: the session was signed out, purged, deleted or cleared while it was in progress.",
            "Federate again."
        )
    }

    nonisolated func requireIdentityPool(for operation: String) throws {
        guard configuration.identityPool != nil else {
            throw AuthClientError.configuration(
                "This session cannot \(operation): the configuration has no identity pool.",
                "Add an identity pool to the configuration (the auth section of amplify_outputs.json)."
            )
        }
    }
}
