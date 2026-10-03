//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

// `.default` runs the Auth plugin's configuration-change rule before it reads (`SessionRecordStore+PluginConfiguration.swift`):
// at restore, and first in the static `signOutStoredSession` and `purgeStoredSession`, so each acts on what a restore
// would see. A login the rule deleted is revoked here, best effort and off the restore's path.
extension SessionCore {

    /// The engine configuration `.default` records for the Auth plugin, and runs the plugin's rule with.
    nonisolated var pluginConfiguration: AuthConfiguration {
        AuthConfiguration(client: configuration)
    }

    /// Runs the plugin's rule through `store`, under the gates the caller holds, then starts the revoke of a deleted
    /// login if `revocablePayload` allows one, also when recording the configuration afterwards failed.
    /// `onlyIfCarrying` is the static calls' form: the rule applies only when it carries, and records no
    /// configuration.
    ///
    /// - Returns: What the rule did: for the static sign-out, the record it carried from.
    /// - Throws: `AuthClientError.storageUnavailable` if storage failed; `SessionRecordStore.CarrySourceChanged` if
    ///   the previous configuration no longer names `heldSource`.
    @discardableResult
    static func applyPluginConfigurationRule(
        through store: SessionRecordIO,
        current: AuthConfiguration,
        heldSource: PoolNamespace??,
        onlyIfCarrying: Bool = false,
        makeRevoker: @escaping @Sendable (AuthConfiguration) -> any SessionRevoker
    ) async throws -> SessionRecordStore.PluginConfigurationOutcome {
        let applied = try await store.perform { store -> AppliedPluginRule in
            let applied = try store.applyPluginConfigurationRuleReportingRecord(
                current: current,
                heldSource: heldSource,
                onlyIfCarrying: onlyIfCarrying
            )
            guard case .cleared(_, let previous) = applied.outcome,
                  let payload = store.revocablePayload(after: applied.outcome, current: current) else {
                return AppliedPluginRule(outcome: applied.outcome, revocable: nil, recordFailure: applied.recordFailure)
            }
            return AppliedPluginRule(outcome: applied.outcome, revocable: (payload, previous), recordFailure: applied.recordFailure)
        }
        // A deleted login is revoked even if recording the configuration then failed: it is gone
        // from this device either way, and the next restore finds nothing left to delete, or to revoke.
        if let revocable = applied.revocable {
            startRevoke(revocable.payload, previous: revocable.previous, makeRevoker: makeRevoker)
        }
        if let failure = applied.recordFailure {
            throw failure
        }
        return applied.outcome
    }

    /// After a static sign-out that carried `.default`'s login from `source`, signs out that record too,
    /// under the gates the static call holds, which include the source's namespace: otherwise a restore under the
    /// configuration the app last ran with, or a later move to this one, would bring the signed-out user back. Only
    /// while it still holds exactly the bytes carried; another writer's record is left alone. Best effort: the session
    /// is signed out here either way, and a failure logs one warning, naming no one.
    static func signOutCarrySource(_ source: String, carried bytes: Data, through store: SessionRecordIO) async {
        do {
            _ = try await store.perform { try $0.signOutCarrySource(source, carried: bytes) }
        } catch {
            ClientLog.logger(ClientLog.defaultSession).warn(carrySourceSignOutFailedWarning)
        }
    }

    /// What a failed `signOutCarrySource` logs.
    static let carrySourceSignOutFailedWarning =
        "The default session's login under the configuration it was carried from could not be signed out. "
            + "A restore under that configuration may find it signed in."

    /// Revokes a deleted login once, detached, so the restore never waits on the network, and the revoker is built
    /// there, not under the record's gates. A failure logs one warning, naming no one: the refresh token then stays
    /// valid until it expires.
    @discardableResult
    static func startRevoke(
        _ payload: Data,
        previous: AuthConfiguration,
        makeRevoker: @escaping @Sendable (AuthConfiguration) -> any SessionRevoker
    ) -> Task<Void, Never> {
        Task.detached {
            let revoked: Bool
            do {
                revoked = try await makeRevoker(previous).revoke(payload).revokeError == nil
            } catch {
                revoked = false
            }
            guard !revoked else {
                return
            }
            ClientLog.logger(ClientLog.defaultSession).warn(
                "A login deleted by a configuration change could not be revoked; its refresh token stays valid until it expires."
            )
        }
    }
}

/// What `SessionCore.applyPluginConfigurationRule` did under the store's queue: the rule's outcome, the deleted login to
/// revoke, if any, and a failure to record the configuration afterwards.
private struct AppliedPluginRule: Sendable {
    let outcome: SessionRecordStore.PluginConfigurationOutcome
    let revocable: (payload: Data, previous: AuthConfiguration)?
    let recordFailure: AuthClientError?
}
