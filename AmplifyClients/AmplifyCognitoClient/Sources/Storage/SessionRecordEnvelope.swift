//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// What a caller reads from and writes to a session record: the credentials, plus the listing
/// metadata a picker renders without decoding them.
struct SessionRecord: Equatable, Sendable {

    /// The app-supplied display name. Survives sign-out.
    var label: String?

    /// The signed-in user's name, `nil` for guest and federated sessions.
    var username: String?

    /// The signed-in user's unique ID, the user pool `sub`. `nil` for guest and federated sessions, and
    /// for records written before this key existed. It lets a restore say who is signed in without
    /// decoding the credentials. An additive key, so it needs no schema bump: a version-1 reader that
    /// predates it ignores it.
    var userId: String?

    /// What the record holds. `.signedOut` for a signed-out row.
    var kind: SessionKind

    /// The serialized credentials, opaque to this layer. `nil` once signed out.
    var credentials: Data?

    /// Whether the credentials are user pool tokens carried forward from another pool namespace into a
    /// configuration with an identity pool (`SessionRecordStore.readCarryingForward`), so the session has no
    /// identity yet. The core refreshes such a record the first time it is asked for anything, and the
    /// engine's refresh of user-pool-only credentials with an identity pool configured fetches the
    /// identity and its AWS credentials: the identity is obtained lazily, never at restore. An additive
    /// key, written only when `true`, so it needs no schema bump.
    var identityPending: Bool = false

    /// A row that is kept after sign-out so a picker can still offer it, holding no credentials.
    static func signedOut(label: String?, username: String?, userId: String? = nil) -> SessionRecord {
        SessionRecord(label: label, username: username, userId: userId, kind: .signedOut, credentials: nil)
    }

    var isSignedOut: Bool {
        kind == .signedOut && credentials == nil
    }
}

/// The frozen, versioned format a session record is stored in.
///
/// ```json
/// {"credentials":"dG9rZW5z","generation":3,"kind":"userPoolAndIdentityPool",
///  "label":"Acme Corp","lastWriteTimestamp":1790000000123,"schemaVersion":1,"userId":"sub-1",
///  "username":"alice"}
/// ```
///
/// **The stored format is frozen.** Every key is spelled in `CodingKeys` and every value is encoded by
/// hand, so neither renaming a Swift property nor changing an encoder's date or data strategy can change
/// what is on disk. `label`, `username`, `userId` and `credentials` are omitted when `nil`. `userId`
/// was added to version 1 as a purely additive key.
///
/// **Any change a version-1 reader cannot interpret bumps `schemaVersion`** — including a new
/// `SessionKind` value. A reader classifies a higher version as `unsupportedSchema`, which is neither
/// corrupt nor absent, so a newer binary's record is skipped and never overwritten or deleted by an
/// older one. Purely additive keys do not need a bump: readers ignore keys they do not know.
struct SessionRecordEnvelope: Equatable, Sendable {

    /// The newest schema this build reads and the one it writes.
    static let currentSchemaVersion = 1

    let schemaVersion: Int

    /// Bumped by exactly one on every committed write. The commit guard's discriminator: a writer
    /// commits only if the stored generation still equals the one it read.
    let generation: UInt64

    /// When the record was last committed, at millisecond precision (the stored resolution).
    let lastWriteTimestamp: Date

    let record: SessionRecord

    init(schemaVersion: Int = currentSchemaVersion, generation: UInt64, lastWriteTimestamp: Date, record: SessionRecord) {
        self.schemaVersion = schemaVersion
        self.generation = generation
        self.lastWriteTimestamp = Self.roundedToMilliseconds(lastWriteTimestamp)
        self.record = record
    }

    private static func roundedToMilliseconds(_ date: Date) -> Date {
        Date(timeIntervalSince1970: TimeInterval(milliseconds(of: date)) / 1_000)
    }

    fileprivate static func milliseconds(of date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1_000).rounded())
    }
}

// MARK: - Stored format

extension SessionRecordEnvelope: Codable {

    /// The on-disk key names. Changing a raw value here changes the stored format.
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case generation
        case lastWriteTimestamp
        case label
        case username
        case userId
        case kind
        case credentials
        case identityPending
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        let generation = try container.decode(UInt64.self, forKey: .generation)
        let milliseconds = try container.decode(Int64.self, forKey: .lastWriteTimestamp)

        let kindValue = try container.decode(String.self, forKey: .kind)
        guard let kind = SessionKind(storedValue: kindValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "\"\(kindValue)\" is not a session kind this schema version defines."
            )
        }

        let credentials: Data?
        if let base64 = try container.decodeIfPresent(String.self, forKey: .credentials) {
            guard let data = Data(base64Encoded: base64) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .credentials,
                    in: container,
                    debugDescription: "The credentials are not valid base64."
                )
            }
            credentials = data
        } else {
            credentials = nil
        }

        self.init(
            schemaVersion: schemaVersion,
            generation: generation,
            lastWriteTimestamp: Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1_000),
            record: SessionRecord(
                label: try container.decodeIfPresent(String.self, forKey: .label),
                username: try container.decodeIfPresent(String.self, forKey: .username),
                userId: try container.decodeIfPresent(String.self, forKey: .userId),
                kind: kind,
                credentials: credentials,
                identityPending: try container.decodeIfPresent(Bool.self, forKey: .identityPending) ?? false
            )
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(generation, forKey: .generation)
        try container.encode(Self.milliseconds(of: lastWriteTimestamp), forKey: .lastWriteTimestamp)
        try container.encodeIfPresent(record.label, forKey: .label)
        try container.encodeIfPresent(record.username, forKey: .username)
        try container.encodeIfPresent(record.userId, forKey: .userId)
        try container.encode(record.kind.storedValue, forKey: .kind)
        try container.encodeIfPresent(record.credentials?.base64EncodedString(), forKey: .credentials)
        if record.identityPending {
            try container.encode(true, forKey: .identityPending)
        }
    }
}

extension SessionKind {

    /// The stored spelling of each kind. Frozen: it is part of the record format.
    var storedValue: String {
        switch self {
        case .userPoolOnly: return "userPoolOnly"
        case .userPoolAndIdentityPool: return "userPoolAndIdentityPool"
        case .guest: return "guest"
        case .federated: return "federated"
        case .signedOut: return "none"
        }
    }

    init?(storedValue: String) {
        switch storedValue {
        case "userPoolOnly": self = .userPoolOnly
        case "userPoolAndIdentityPool": self = .userPoolAndIdentityPool
        case "guest": self = .guest
        case "federated": self = .federated
        case "none": self = .signedOut
        default: return nil
        }
    }
}

// MARK: - Encoding and classification

extension SessionRecordEnvelope {

    /// What a stored blob turned out to be.
    enum Decoded: Equatable, Sendable {
        /// A record this build can read.
        case envelope(SessionRecordEnvelope)
        /// A well-formed record written by a newer schema. Present, not readable here, and not corrupt.
        case unsupportedSchema(version: Int)
        /// Bytes that are not a record of any schema version.
        case corrupt
    }

    /// The fields every schema version must keep, read before anything else so a newer record is
    /// recognised as newer rather than misreported as corrupt.
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
        guard let envelope = try? decoder.decode(SessionRecordEnvelope.self, from: data) else {
            return .corrupt
        }
        return .envelope(envelope)
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }
}
