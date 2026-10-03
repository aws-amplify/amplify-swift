//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// What `.default` keeps beside the Auth plugin's record, which has no room for it: the session's display
/// label, and the last signed-in user, for the signed-out row a picker shows.
///
/// Stored under its own account, `SessionRecordKey.metaAccount(in:)`
/// (`amplify.1.<poolNamespace>.$default.meta`), which no listing reads as a session.
///
/// ```json
/// {"label":"Acme Corp","lastWriteTimestamp":1790000000123,"schemaVersion":1,"userId":"sub-1","username":"alice"}
/// ```
///
/// **The stored format is frozen.** Every key is spelled in `CodingKeys` and every value is encoded by hand, with
/// sorted keys, so neither renaming a Swift property nor changing an encoder's strategies can change what is on
/// disk. `label`, `username` and `userId` are omitted when `nil`. As for `SessionRecordEnvelope`, any change a
/// version-1 reader cannot interpret bumps `schemaVersion`; purely additive keys do not, since readers ignore
/// keys they do not know.
///
/// **It is bound to a user** (`applies(toRecordUser:recordIsSignedOut:)`), so a label never passes from one
/// user to another.
struct DefaultSessionMeta: Equatable, Sendable {

    /// The newest schema this build reads and the one it writes.
    static let currentSchemaVersion = 1

    let schemaVersion: Int

    /// When the sidecar was last written, at millisecond precision (the stored resolution).
    let lastWriteTimestamp: Date

    /// The app-supplied display name of `.default`.
    var label: String?

    /// The last signed-in user's name: what a signed-out row shows.
    var username: String?

    /// The last signed-in user's unique ID, the user pool `sub`: the user the sidecar is bound to. `nil` while no
    /// user has signed in since the sidecar was written, as for a label set before anyone signed in.
    var userId: String?

    init(
        schemaVersion: Int = currentSchemaVersion,
        lastWriteTimestamp: Date,
        label: String?,
        username: String?,
        userId: String?
    ) {
        self.schemaVersion = schemaVersion
        self.lastWriteTimestamp = Self.roundedToMilliseconds(lastWriteTimestamp)
        self.label = label
        self.username = username
        self.userId = userId
    }

    // MARK: Binding to a user

    /// Whether this sidecar describes what the plugin's record now holds, so its label is used and kept.
    ///
    /// The rules:
    /// 1. While the record holds the sidecar's user, it applies.
    /// 2. While the record is signed out (`{"noCredentials":{}}`) or absent, it applies: the picker shows a
    ///    signed-out row with its label and last username.
    /// 3. While the record holds a different principal, it does not apply: another user, or a guest or
    ///    federated identity where the sidecar names a user. Its label is dropped, and the next write rewrites
    ///    the sidecar for the new principal, with no label.
    /// 4. A sidecar with no user yet (a label set before anyone signed in) applies whatever the record holds, so
    ///    the label is kept when a user signs in.
    ///
    /// - Parameters:
    ///   - userId: The record's user, the user pool `sub` of its `signedInData`; `nil` for a guest, federated,
    ///     signed-out or absent record.
    ///   - recordIsSignedOut: Whether the record is signed out or absent.
    func applies(toRecordUser userId: String?, recordIsSignedOut: Bool) -> Bool {
        if recordIsSignedOut {
            return true
        }
        guard let boundUser = self.userId else {
            return true
        }
        return boundUser == userId
    }

    // MARK: Milliseconds

    private static func roundedToMilliseconds(_ date: Date) -> Date {
        Date(timeIntervalSince1970: TimeInterval(milliseconds(of: date)) / 1_000)
    }

    fileprivate static func milliseconds(of date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1_000).rounded())
    }
}

// MARK: - Stored format

extension DefaultSessionMeta: Codable {

    /// The on-disk key names. Changing a raw value here changes the stored format.
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case lastWriteTimestamp
        case label
        case username
        case userId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let milliseconds = try container.decode(Int64.self, forKey: .lastWriteTimestamp)
        try self.init(
            schemaVersion: container.decode(Int.self, forKey: .schemaVersion),
            lastWriteTimestamp: Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1_000),
            label: container.decodeIfPresent(String.self, forKey: .label),
            username: container.decodeIfPresent(String.self, forKey: .username),
            userId: container.decodeIfPresent(String.self, forKey: .userId)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(Self.milliseconds(of: lastWriteTimestamp), forKey: .lastWriteTimestamp)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(userId, forKey: .userId)
    }
}

// MARK: - Encoding and classification

extension DefaultSessionMeta {

    /// What a stored sidecar turned out to be.
    enum Decoded: Equatable, Sendable {
        /// A sidecar this build can read.
        case meta(DefaultSessionMeta)
        /// A well-formed sidecar written by a newer schema: shown as absent, and never overwritten.
        case unsupportedSchema(version: Int)
        /// Bytes that are not a sidecar of any schema version: shown as absent. The sidecar is cosmetic, so the
        /// next write replaces it.
        case corrupt
    }

    /// The field every schema version must keep, read first so a newer sidecar is recognised as newer rather
    /// than misreported as corrupt.
    private struct VersionProbe: Decodable {
        let schemaVersion: Int
    }

    static func decode(_ data: Data) -> Decoded {
        let decoder = JSONDecoder()
        guard let probe = try? decoder.decode(VersionProbe.self, from: data),
              probe.schemaVersion >= 1 else {
            return .corrupt
        }
        guard probe.schemaVersion <= currentSchemaVersion else {
            return .unsupportedSchema(version: probe.schemaVersion)
        }
        guard let meta = try? decoder.decode(DefaultSessionMeta.self, from: data) else {
            return .corrupt
        }
        return .meta(meta)
    }

    /// The stored form: sorted keys, `nil` fields omitted.
    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }
}
