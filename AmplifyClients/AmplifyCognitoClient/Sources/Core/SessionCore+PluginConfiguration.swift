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
    /// login if `revocablePayload` allows one. `onlyIfCarrying` is the static calls' form: the rule applies only
    /// when it carries.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if storage failed; `SessionRecordStore.CarrySourceChanged` if
    ///   the previous configuration no longer names `heldSource`.
    static func applyPluginConfigurationRule(
        through store: SessionRecordIO,
        current: AuthConfiguration,
        heldSource: PoolNamespace??,
        onlyIfCarrying: Bool = false,
        makeRevoker: @escaping @Sendable (AuthConfiguration) -> any SessionRevoker
    ) async throws {
        let revocable = try await store.perform { store -> (payload: Data, previous: AuthConfiguration)? in
            let outcome = try store.applyPluginConfigurationRule(current: current, heldSource: heldSource, onlyIfCarrying: onlyIfCarrying)
            guard case .cleared(_, let previous) = outcome,
                  let payload = store.revocablePayload(after: outcome, current: current) else {
                return nil
            }
            return (payload, previous)
        }
        if let revocable {
            startRevoke(revocable.payload, previous: revocable.previous, makeRevoker: makeRevoker)
        }
    }

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
