//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Reads, and only reads, the record the standalone Cognito client keeps for its default session, so
/// that a release of this plugin shipped before that client can still find a user the client signed in.
///
/// The client stores each session under `amplify.1.<pool namespace>.<session ID>.session`, a sibling of
/// this plugin's own `amplify.<pool namespace>.session` in the same keychain service and access group.
/// Its default session, `$default`, is the one that stands for this plugin's user, and is the only one
/// read here.
///
/// **Read only.** Nothing that reads or ends a session here writes or deletes an `amplify.1.` item. Those
/// records belong to the client, whose commit guard cannot see a second writer, and deleting one would
/// take a session away from a client build the app may roll forward to. `KeychainItemMigrator` is not a
/// way to reach them either: `SecItemUpdate` moves an item rather than copying it, so it is never
/// rollback-safe. (The credential store's access-group handling at construction is outside this rule
/// until the scoped-wipe fix lands.)
///
/// The record is a JSON envelope whose `credentials` value is the base64 of this plugin's own
/// `AmplifyCredentials` JSON:
///
/// ```json
/// {"credentials":"eyJ1c2VyUG9vbE9ubHkiOnsuLi59fQ==","generation":3,"kind":"userPoolOnly",
///  "label":"Work","lastWriteTimestamp":1790000000123,"schemaVersion":1,"username":"alice"}
/// ```
///
/// `schemaVersion`, `generation`, `lastWriteTimestamp`, `kind` and `credentials` are decoded, and the
/// first four are required, exactly as the client's own decoder requires them. Every other key, including
/// any a later version-1 writer adds, is ignored. A `schemaVersion` other than 1 means a format this
/// release does not understand, and the record is ignored rather than guessed at.
package enum DefaultSessionRecordReader {

    /// The one schema version this reader understands, and the version segment of the account name.
    package static let supportedSchemaVersion = 1

    /// The stored spelling of the client's default session ID.
    package static let defaultSessionID = "$default"

    /// What a default-session record turned out to hold.
    package enum Record {
        /// A signed-in session, with credentials in this plugin's own format.
        case signedIn(AmplifyCredentials)
        /// A row the client keeps after signing out. It holds no session.
        case signedOut
        /// Present, but not something this release can read: a newer schema, or bytes that are not a
        /// version-1 record. Ignored, and never overwritten or deleted.
        case unreadable(reason: String)
    }

    /// The account of the default session's record for a pool namespace, the part of this plugin's
    /// keys between `amplify.` and `.session`.
    package static func account(forPoolNamespace poolNamespace: String) -> String {
        "amplify.\(supportedSchemaVersion).\(poolNamespace).\(defaultSessionID).session"
    }

    /// Reads the record stored under `account`.
    ///
    /// - Returns: `nil` if no item is stored there.
    /// - Throws: Any keychain failure other than "not found", unchanged. A record that cannot be read
    ///   is never reported as absent.
    package static func read(_ account: String, from keychain: EngineKeychainStore) throws -> Record? {
        let data: Data
        do {
            data = try keychain._getData(account)
        } catch EngineCredentialStoreError.itemNotFound {
            return nil
        }
        return decode(data)
    }

    /// Classifies a stored record.
    package static func decode(_ data: Data) -> Record {
        let decoder = JSONDecoder()
        guard let probe = try? decoder.decode(VersionProbe.self, from: data) else {
            return .unreadable(reason: "the record has no schema version")
        }
        guard probe.schemaVersion == supportedSchemaVersion else {
            return .unreadable(reason: "schema version \(probe.schemaVersion) is not supported")
        }
        guard let envelope = try? decoder.decode(EnvelopeV1.self, from: data) else {
            return .unreadable(reason: "the record is not a version \(supportedSchemaVersion) record")
        }
        guard let kind = Kind(rawValue: envelope.kind) else {
            return .unreadable(reason: "\"\(envelope.kind)\" is not a version \(supportedSchemaVersion) session kind")
        }
        if kind == .none {
            // The client's signed-out row: `kind` none *and* no credentials. Either without the other is
            // not a shape the client writes.
            guard envelope.credentials == nil else {
                return .unreadable(reason: "a signed-out record holds credentials")
            }
            return .signedOut
        }
        guard let base64 = envelope.credentials else {
            return .unreadable(reason: "a signed-in record has no credentials")
        }
        guard let payload = Data(base64Encoded: base64),
              let credentials = try? decoder.decode(AmplifyCredentials.self, from: payload) else {
            return .unreadable(reason: "the credentials are not readable")
        }
        if case .noCredentials = credentials {
            return .signedOut
        }
        return .signedIn(credentials)
    }

    /// Read on its own first, so a newer record is recognised by its version whatever its other fields
    /// have become.
    private struct VersionProbe: Decodable {
        let schemaVersion: Int
    }

    /// The version-1 fields this reader decodes. `Decodable`'s synthesized conformance ignores every key
    /// not declared here. `generation` and `lastWriteTimestamp` are not used, only required, so that a
    /// record the client itself would call corrupt is not signed in from here.
    private struct EnvelopeV1: Decodable {
        let generation: UInt64
        let lastWriteTimestamp: Int64
        let kind: String
        let credentials: String?
    }

    /// The version-1 session kinds, as stored. A kind outside this set would be a change a version-1
    /// reader cannot interpret, which the client's format rule says comes with a new schema version.
    private enum Kind: String {
        case userPoolOnly
        case userPoolAndIdentityPool
        case guest
        case federated
        case none
    }
}
