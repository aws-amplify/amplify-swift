//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The pool identifiers a stored record is scoped to.
///
/// This reproduces exactly what `AWSCognitoAuthPlugin` already puts in its keys, so a record
/// written by either can be found by the other. Its component count varies with the
/// configuration, and the two single-pool forms are indistinguishable once rendered — which is
/// why `SessionRecordKey.parse` never relies on segment arity.
enum PoolNamespace: Hashable, Sendable {
    case userPool(String)
    case identityPool(String)
    case userPoolAndIdentityPool(userPoolId: String, identityPoolId: String)

    /// The user pool ID, if this namespace has a user pool.
    var userPoolId: String? {
        switch self {
        case .userPool(let userPoolId), .userPoolAndIdentityPool(let userPoolId, _):
            return userPoolId
        case .identityPool:
            return nil
        }
    }

    var keyComponent: String {
        switch self {
        case .userPool(let poolId), .identityPool(let poolId):
            return poolId
        case .userPoolAndIdentityPool(let userPoolId, let identityPoolId):
            return "\(userPoolId).\(identityPoolId)"
        }
    }

    /// The namespace a rendered component names, as a namespace marker records it
    /// (`SessionRecordStore+CopyForward.swift`). The two single-pool forms are told apart by their IDs'
    /// shapes: an identity pool ID is `<region>:<uuid>`, a user pool ID `<region>_<id>`, and neither contains
    /// `.`. `nil` for anything else.
    init?(keyComponent: String) {
        let parts = keyComponent.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        func isIdentityPool(_ id: String) -> Bool { id.contains(":") }
        switch parts.count {
        case 1 where !parts[0].isEmpty:
            self = isIdentityPool(parts[0]) ? .identityPool(parts[0]) : .userPool(parts[0])
        case 2 where !parts[0].isEmpty && !isIdentityPool(parts[0]) && isIdentityPool(parts[1]):
            self = .userPoolAndIdentityPool(userPoolId: parts[0], identityPoolId: parts[1])
        default:
            return nil
        }
    }
}

/// The keychain account names session records are stored under.
///
/// Format v1: `amplify.1.<poolNamespace>.<sessionId>.<kind>`. The `1` is a schema version, added
/// while it is free. The session segment is an insertion relative to the plugin's
/// `amplify.<poolNamespace>.session`, so the two records are siblings under one service rather
/// than one replacing the other, and a rollback to a plugin-only release still finds its record.
enum SessionRecordKey {

    enum Kind: String, CaseIterable, Sendable {
        /// Tokens and credentials.
        case session
        /// A partly-completed sign-in, persisted so it survives the app being killed.
        case challenge
    }

    struct Parsed: Equatable, Sendable {
        let namespaceComponent: String
        let sessionId: SessionID
        let kind: Kind
    }

    static let schemaVersion = "1"
    private static let versionedPrefix = "amplify.\(schemaVersion)."

    static func account(for sessionId: SessionID, in namespace: PoolNamespace, kind: Kind) -> String {
        account(for: sessionId, namespaceComponent: namespace.keyComponent, kind: kind)
    }

    /// The same account, for a namespace known only by its rendered component, as a listing parses it.
    static func account(for sessionId: SessionID, namespaceComponent: String, kind: Kind) -> String {
        "\(versionedPrefix)\(namespaceComponent).\(sessionId.stringValue).\(kind.rawValue)"
    }

    /// The account `AWSCognitoAuthPlugin` stores its single session under today.
    static func legacySessionAccount(in namespace: PoolNamespace) -> String {
        "amplify.\(namespace.keyComponent).session"
    }

    /// Recognises a v1 session-record account and splits it apart.
    ///
    /// Returns `nil` for anything else in the keychain service — the plugin's legacy record,
    /// device metadata, the stored configuration, a future schema version — so listing can run
    /// over the whole service without misreading any of them. Parsing anchors on the prefix and the
    /// suffix, and takes the session ID as the last segment before the suffix: a session ID cannot
    /// contain `.`, so that split is unambiguous however many segments the pool namespace has.
    static func parse(_ account: String) -> Parsed? {
        guard account.hasPrefix(versionedPrefix) else {
            return nil
        }
        let remainder = account.dropFirst(versionedPrefix.count)
        guard let lastDot = remainder.lastIndex(of: "."),
              let kind = Kind(rawValue: String(remainder[remainder.index(after: lastDot)...])) else {
            return nil
        }
        let body = remainder[..<lastDot]
        guard let sessionDot = body.lastIndex(of: ".") else {
            return nil
        }
        let namespaceComponent = String(body[..<sessionDot])
        guard !namespaceComponent.isEmpty,
              let sessionId = SessionID(storageComponent: String(body[body.index(after: sessionDot)...])) else {
            return nil
        }
        return Parsed(namespaceComponent: namespaceComponent, sessionId: sessionId, kind: kind)
    }

    // MARK: Namespace markers

    /// The last segment of a namespace marker's account: not a `Kind`, so `parse` (and so every listing, of
    /// this build and of earlier ones) never reads a marker as a session record.
    static let markerSuffix = "configuration"

    /// The account of a session's namespace marker for one app: `amplify.1.<sessionId>.<scope>.configuration`
    /// (`SessionRecordStore+CopyForward.swift`). `scope` names the app (a digest of its bundle identifier),
    /// so an app and its extension sharing an access group each keep their own.
    static func markerAccount(for sessionId: SessionID, scope: String) -> String {
        "\(versionedPrefix)\(sessionId.stringValue).\(scope).\(markerSuffix)"
    }

    /// The session a namespace marker account of `scope` belongs to, or `nil` for any other account.
    static func parseMarker(_ account: String, scope: String) -> SessionID? {
        let suffix = ".\(scope).\(markerSuffix)"
        guard account.hasPrefix(versionedPrefix), account.hasSuffix(suffix) else {
            return nil
        }
        let body = account.dropFirst(versionedPrefix.count).dropLast(suffix.count)
        return body.contains(".") ? nil : SessionID(storageComponent: String(body))
    }
}
