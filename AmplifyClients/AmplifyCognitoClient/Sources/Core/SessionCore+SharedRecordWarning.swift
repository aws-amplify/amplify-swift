//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

// TEMPORARY: removed by the plugin bridge, which makes the Auth plugin use this client for the
// default session, so there is no second writer left to warn about.
//
// `.default` shares the Auth plugin's saved login. The Auth plugin running beside this client over the
// default session is not supported: each keeps its own tokens in memory. When `.default` re-reads the
// shared record and finds a different principal from the one it holds, another writer, such as the plugin, signed
// someone else in, or a guest. It logs one warning, naming no one.
extension SessionCore {

    /// The warning. It names no user, `sub`, identity ID or session ID.
    static let sharedRecordHoldsAnotherPrincipalWarning = "The default session's saved login now holds a different user or a guest than this client held. The Auth plugin may be running beside this client over the default session, which is not supported."

    /// Compares a record `.default`'s core re-read under its gate (`withRecord`) with the snapshot it holds in memory.
    /// Only `.default`'s I/O calls it (`recordIO()`): a named session never hops here.
    ///
    /// - Parameter sessionId: The session the record was read for. Only this core's own record counts.
    nonisolated func noteReread(_ reread: SessionSnapshot, of sessionId: SessionID) async {
        // A core that has already warned never hops onto the actor again.
        guard sessionId == self.sessionId, !sharedRecordWarning.hasWarned else {
            return
        }
        guard let previous = await restoredSnapshotIfAny else {
            return
        }
        warnIfSharedRecordChangedPrincipal(previous: previous, reread: reread)
    }

    /// Logs the warning, once per core, at `warn`, under `AmplifyCognitoClient.DefaultSession`, when `.default`'s
    /// `reread` record holds a principal provably different from the one `previous`, held in memory, holds.
    ///
    /// A principal is a user (the `sub`, else the username), or, with no user, an identity ID: a guest, or a federated
    /// identity. So another user, a guest over a user and a user over a guest all count. A record
    /// with no principal (signed out, absent, unreadable) never does, on either side, and neither does the same
    /// principal with new credentials (the same user refreshed, the same guest's credentials refreshed).
    nonisolated func warnIfSharedRecordChangedPrincipal(previous: SessionSnapshot, reread: SessionSnapshot) {
        guard sessionId == .default,
              // The same bytes hold the same principal: nothing to describe.
              previous.credentials != reread.credentials,
              let held = SharedRecordPrincipal(previous, engine: engine),
              let found = SharedRecordPrincipal(reread, engine: engine),
              held.isProvablyDifferent(from: found),
              sharedRecordWarning.claim()
        else {
            return
        }
        ClientLog.logger(ClientLog.defaultSession).warn(Self.sharedRecordHoldsAnotherPrincipalWarning)
    }
}

/// Who a `.default` snapshot holds, for the temporary warning (`SessionCore+SharedRecordWarning.swift`).
enum SharedRecordPrincipal: Equatable {
    /// A user pool user: the `sub` and the username, as far as known.
    case user(userId: String?, username: String?)
    /// No user: a guest's or a federated identity's identity pool identity.
    case identity(String)

    /// The principal `snapshot` holds, or `nil` if it holds none, or none this can name: signed out, absent,
    /// unreadable, or credentials with neither a user nor an identity.
    init?(_ snapshot: SessionSnapshot, engine: any SessionEngine) {
        guard let record = snapshot.ownRecord, record.kind != .signedOut, let credentials = record.credentials else {
            return nil
        }
        let described = try? engine.describe(credentials)
        let userId = record.userId ?? described?.userId
        let username = record.username ?? described?.username
        if userId != nil || username != nil {
            self = .user(userId: userId, username: username)
        } else if let identityId = described?.identityId {
            self = .identity(identityId)
        } else {
            return nil
        }
    }

    /// Whether `other` is provably someone else: another `sub` (else another username, when either `sub` is
    /// unknown), another identity ID, or a user on one side and an identity on the other. Two users with nothing
    /// to compare are not.
    func isProvablyDifferent(from other: SharedRecordPrincipal) -> Bool {
        switch (self, other) {
        case (.user(let userId, let username), .user(let otherUserId, let otherUsername)):
            if let userId, let otherUserId {
                return userId != otherUserId
            }
            if let username, let otherUsername {
                return username != otherUsername
            }
            return false
        case (.identity(let identityId), .identity(let otherIdentityId)):
            return identityId != otherIdentityId
        case (.user, .identity), (.identity, .user):
            return true
        }
    }
}

/// Whether a core has logged the shared record's warning: it logs once per core.
final class SharedRecordWarningLatch: @unchecked Sendable {

    // `@unchecked Sendable`: `warned` is only touched while holding `lock`.
    private let lock = NSLock()
    private var warned = false

    var hasWarned: Bool {
        lock.withLock { warned }
    }

    /// `true` the first time only: the caller logs.
    func claim() -> Bool {
        lock.withLock {
            guard !warned else {
                return false
            }
            warned = true
            return true
        }
    }
}
