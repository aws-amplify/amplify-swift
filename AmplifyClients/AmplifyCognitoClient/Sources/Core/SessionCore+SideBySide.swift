//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SessionCore {

    /// What is logged, once per core, when `.default` restores its own record while the Auth plugin's record holds
    /// another principal. It names no one: no session ID, user, `sub` or identity ID.
    static let pluginHoldsAnotherSessionWarning =
        "The Auth plugin holds a different session than this client's default session; "
            + "running both over the default session is not supported."

    /// The plugin and the client side by side over the default session is not supported. Once
    /// `.default` has its own record it ignores the plugin's, so a different user signed in through the plugin is
    /// invisible to it. This makes that case visible: when `.default` has restored its own record holding credentials,
    /// it reads the plugin's record once and, if that holds a different signed-in principal, logs one warning.
    ///
    /// Started by `adoptRestored`, after the restored snapshot is installed, at most once per core; `nil` when there is
    /// nothing to check. **Fire and forget, outside the restore:** not under the record's gate, not in the restore's
    /// flight, and on the listings' concurrent queue rather than the record's serial one, so a plugin-key read that
    /// stalls never delays or fails the restore, holds the gate, or queues this record's later I/O behind it. Outside
    /// the gate is safe: a concurrent purge or sign-out only deletes the plugin's record, so the check is silent if it
    /// lands first; a warning may otherwise follow it. The task holds the store and the engine, not the core, so it
    /// never keeps a released session's core alive; while a stalled read waits, though, the engine and its SDK clients
    /// outlive the core.
    ///
    /// Read-only and best effort: it writes and deletes nothing, and a failed read, or a record either side cannot
    /// describe, logs nothing.
    nonisolated func startPluginPrincipalCheck(besides restored: SessionSnapshot) -> Task<Void, Never>? {
        guard sessionId == .default,
              let own = restored.ownRecord,
              own.kind != .signedOut,
              own.credentials != nil else {
            return nil
        }
        let io = SessionRecordIO(store: store, queue: SessionRecordIO.listingQueue)
        let engine = engine
        let sessionId = sessionId
        return Task.detached {
            guard let plugin = try? await io.pluginRecord(for: sessionId),
                  Self.pluginHoldsAnotherPrincipal(plugin, besides: own, engine: engine) else {
                return
            }
            ClientEngineLogger().warn(Self.pluginHoldsAnotherSessionWarning, nil)
        }
    }

    /// Whether the plugin's record holds a signed-in principal provably not the one in `.default`'s own record.
    static func pluginHoldsAnotherPrincipal(_ plugin: Data, besides own: SessionRecord, engine: any SessionEngine) -> Bool {
        guard !PluginRecordSummary.isSignedOutMarker(plugin),
              let pluginSummary = try? engine.describe(plugin) else {
            return false
        }
        // The record's listing metadata names its user without decoding; a record with no user (a guest, or
        // federated) is described for its identity ID.
        let ownSummary: CredentialSummary? = own.userId != nil || own.username != nil
            ? CredentialSummary(kind: own.kind, username: own.username, userId: own.userId)
            : own.credentials.flatMap { try? engine.describe($0) }
        guard let ownSummary else {
            return false
        }
        return pluginSummary.isProvablyAnotherPrincipal(than: ownSummary)
    }
}

extension CredentialSummary {

    /// Whether this (the plugin's) principal is provably not `own`, both being signed in: two users with different
    /// `sub`s (else user names), a user where `own` holds none (a guest or federated identity), or two user-less
    /// identities with different identity IDs. A side that is signed out, or a comparison with nothing to compare,
    /// answers no, so the warning never fires on doubt. A plugin guest beside `own`'s user answers no too: the plugin
    /// is then signed out of its user pool, not signed in as another user.
    func isProvablyAnotherPrincipal(than own: CredentialSummary) -> Bool {
        guard kind != .signedOut, own.kind != .signedOut else {
            return false
        }
        let hasUser = userId != nil || username != nil
        let ownHasUser = own.userId != nil || own.username != nil
        switch (hasUser, ownHasUser) {
        case (true, true):
            if let userId, let ownUserId = own.userId {
                return userId != ownUserId
            }
            if let username, let ownUsername = own.username {
                return username != ownUsername
            }
            return false
        case (true, false):
            return true
        case (false, true):
            return false
        case (false, false):
            guard let identityId, let ownIdentityId = own.identityId else {
                return false
            }
            return identityId != ownIdentityId
        }
    }
}
