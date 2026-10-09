//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class SessionRecordEnvelopeTests: XCTestCase {

    private let timestamp = Date(timeIntervalSince1970: 1_790_000_000.123)

    private func envelope(_ record: SessionRecord, generation: UInt64 = 3) -> SessionRecordEnvelope {
        SessionRecordEnvelope(generation: generation, lastWriteTimestamp: timestamp, record: record)
    }

    private func jsonObject(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    /// - Given: an envelope with every field set, including a 1 KB label
    /// - When: it is encoded and decoded
    /// - Then:
    ///    - every field survives, with the timestamp at millisecond precision
    func testRoundTripPreservesEveryField() throws {
        let label = String(repeating: "L", count: 1_024)
        let original = envelope(SessionRecord(
            label: label,
            username: "alice@corp",
            kind: .userPoolAndIdentityPool,
            credentials: Data([0x00, 0xff, 0x7b, 0x22])
        ))

        let decoded = SessionRecordEnvelope.decode(try original.encoded())

        XCTAssertEqual(decoded, .envelope(original))
        XCTAssertEqual(original.lastWriteTimestamp.timeIntervalSince1970, 1_790_000_000.123, accuracy: 0.000_5)
        XCTAssertEqual(original.schemaVersion, 1)
    }

    /// The stored format must not change when a Swift property is renamed or an encoder is configured
    /// differently, so the keys and value encodings are pinned literally.
    ///
    /// - Given: an envelope with every field set
    /// - When: it is encoded
    /// - Then:
    ///    - the bytes are exactly the frozen JSON: literal keys, the kind's frozen spelling, the
    ///      credentials as base64, and the timestamp as integer milliseconds since 1970
    func testEncodingIsTheFrozenJSON() throws {
        let data = try envelope(SessionRecord(
            label: "Acme Corp",
            username: "alice",
            userId: "sub-1",
            kind: .userPoolAndIdentityPool,
            credentials: Data("tokens".utf8)
        )).encoded()

        XCTAssertEqual(
            String(decoding: data, as: UTF8.self),
            #"{"credentials":"dG9rZW5z","generation":3,"kind":"userPoolAndIdentityPool","label":"Acme Corp","# +
                #""lastWriteTimestamp":1790000000123,"schemaVersion":1,"userId":"sub-1","username":"alice"}"#
        )
        XCTAssertEqual(
            Set(SessionRecordEnvelope.CodingKeys.allRawValues),
            ["schemaVersion", "generation", "lastWriteTimestamp", "label", "username", "userId", "kind", "credentials"]
        )
    }

    /// `userId` was added to schema version 1 as an additive key, so records written before it existed
    /// must still read, with no user ID, and without a schema bump.
    ///
    /// - Given: literal version-1 JSON with a username but no `userId` key, as an earlier build wrote it
    /// - When: it is decoded, and re-encoded
    /// - Then:
    ///    - it reads with `userId == nil` and every other field intact
    ///    - re-encoding writes no `userId` key and the same schema version
    func testRecordWithoutUserIdStillDecodes() throws {
        let data = Data(#"""
        {"credentials":"dG9rZW5z","generation":3,"kind":"userPoolOnly","label":"Acme Corp",\#
        "lastWriteTimestamp":1790000000123,"schemaVersion":1,"username":"alice"}
        """#.utf8)

        guard case .envelope(let decoded) = SessionRecordEnvelope.decode(data) else {
            return XCTFail("a version-1 record without userId must decode")
        }
        XCTAssertEqual(decoded.record, SessionRecord(
            label: "Acme Corp",
            username: "alice",
            userId: nil,
            kind: .userPoolOnly,
            credentials: Data("tokens".utf8)
        ))
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertFalse(try jsonObject(decoded.encoded()).keys.contains("userId"))
    }

    /// `identityPending` (a record carried forward without its identity) was added to schema version 1 as an
    /// additive key, like `userId`: records without it, as every earlier build wrote them, read unchanged.
    ///
    /// - Given: literal version-1 JSON with no `identityPending` key, and the same record with it `true`
    /// - When: each is decoded, and re-encoded
    /// - Then:
    ///    - the first reads with `identityPending == false`, and re-encodes to exactly the bytes it was read
    ///      from: no key is added, so a record that is not pending stays in the earlier builds' format
    ///    - the second reads with `identityPending == true`, and re-encodes with the key
    func testIdentityPendingIsAnAdditiveKey() throws {
        let data = Data(#"""
        {"credentials":"dG9rZW5z","generation":3,"kind":"userPoolOnly","label":"Acme Corp",\#
        "lastWriteTimestamp":1790000000123,"schemaVersion":1,"userId":"sub-1","username":"alice"}
        """#.utf8)
        guard case .envelope(let decoded) = SessionRecordEnvelope.decode(data) else {
            return XCTFail("a version-1 record without identityPending must decode")
        }
        XCTAssertFalse(decoded.record.identityPending)
        XCTAssertEqual(try decoded.encoded(), data, "a record that is not pending keeps the earlier format")

        var pendingObject = try jsonObject(data)
        pendingObject["identityPending"] = true
        let pendingData = try JSONSerialization.data(withJSONObject: pendingObject)
        guard case .envelope(let pending) = SessionRecordEnvelope.decode(pendingData) else {
            return XCTFail("a record with identityPending must decode")
        }
        XCTAssertTrue(pending.record.identityPending)
        XCTAssertEqual(try jsonObject(pending.encoded())["identityPending"] as? Bool, true)
        XCTAssertEqual(pending.schemaVersion, 1, "no schema bump")
    }

    /// - Given: a signed-in record with a user ID
    /// - When: it is signed out into a kept row, and the row is round-tripped through the stored format
    /// - Then:
    ///    - the user ID is carried forward like the username, and survives the round trip
    func testSignedOutRowCarriesTheUserId() throws {
        let row = SessionRecord.signedOut(label: "Main", username: "alice", userId: "sub-1")
        let original = envelope(row)

        XCTAssertEqual(row.userId, "sub-1")
        XCTAssertTrue(row.isSignedOut)
        XCTAssertEqual(SessionRecordEnvelope.decode(try original.encoded()), .envelope(original))
    }

    /// - Given: a signed-out record, with no label, username or credentials
    /// - When: it is encoded and decoded
    /// - Then:
    ///    - the absent fields are omitted rather than written as null, and it decodes back unchanged
    func testAbsentFieldsAreOmitted() throws {
        let original = envelope(.signedOut(label: nil, username: nil))
        let data = try original.encoded()

        XCTAssertEqual(Set(try jsonObject(data).keys), ["schemaVersion", "generation", "lastWriteTimestamp", "kind"])
        XCTAssertEqual(SessionRecordEnvelope.decode(data), .envelope(original))
    }

    /// - Given: each session kind
    /// - When: its stored spelling is read and parsed back
    /// - Then:
    ///    - the spelling is the frozen literal and parses to the same kind
    func testEveryKindHasAFrozenSpelling() {
        let expected: [(SessionKind, String)] = [
            (.userPoolOnly, "userPoolOnly"),
            (.userPoolAndIdentityPool, "userPoolAndIdentityPool"),
            (.guest, "guest"),
            (.federated, "federated"),
            (.signedOut, "none")
        ]
        for (kind, spelling) in expected {
            XCTAssertEqual(kind.storedValue, spelling)
            XCTAssertEqual(SessionKind(storedValue: spelling), kind)
        }
        XCTAssertNil(SessionKind(storedValue: "UserPoolOnly"), "spellings are case-sensitive")
    }

    /// A v1 reader classifies an unknown `kind` as corrupt — hidden from listing, overwritten by sign-out —
    /// so a new kind must come with a schema bump. This stops the file compiling until whoever adds a
    /// case records the schema version that introduced it.
    ///
    /// - Given: every session kind, reached through an exhaustive switch with no `default`
    /// - When: each is mapped to the schema version that introduced it
    /// - Then:
    ///    - every version is one this build reads, and the version-1 kinds are exactly the five pinned
    ///      spellings
    func testAddingASessionKindRequiresRecordingItsSchemaVersion() {
        func introducedIn(_ kind: SessionKind) -> Int {
            switch kind {
            case .userPoolOnly, .userPoolAndIdentityPool, .guest, .federated, .signedOut:
                return 1
            }
        }
        let pinned: [SessionKind] = [.userPoolOnly, .userPoolAndIdentityPool, .guest, .federated, .signedOut]
        for kind in pinned {
            XCTAssertLessThanOrEqual(introducedIn(kind), SessionRecordEnvelope.currentSchemaVersion)
        }
        XCTAssertEqual(
            Set(pinned.filter { introducedIn($0) == 1 }.map(\.storedValue)),
            ["userPoolOnly", "userPoolAndIdentityPool", "guest", "federated", "none"]
        )
    }

    /// - Given: hand-written v1 JSON, as a reader will find it on disk, with an extra key a later
    ///   additive change might write
    /// - When: it is decoded
    /// - Then:
    ///    - it reads, and the unknown key is ignored
    func testDecodesHandWrittenRecordAndIgnoresUnknownKeys() {
        let data = Data(#"""
        {"schemaVersion":1,"generation":7,"lastWriteTimestamp":1790000000000,"kind":"guest",
         "credentials":"Z3Vlc3Q=","addedLater":{"anything":[1,2]}}
        """#.utf8)

        XCTAssertEqual(SessionRecordEnvelope.decode(data), .envelope(SessionRecordEnvelope(
            generation: 7,
            lastWriteTimestamp: Date(timeIntervalSince1970: 1_790_000_000),
            record: SessionRecord(label: nil, username: nil, kind: .guest, credentials: Data("guest".utf8))
        )))
    }

    /// The stored spelling kept its name when the case was renamed, so records already on disk still read.
    ///
    /// - Given: a hand-written v1 signed-out row, `"kind":"none"` with a label and a username and no
    ///   credentials, as an earlier build wrote it
    /// - When: it is decoded, and re-encoded
    /// - Then:
    ///    - it reads as `.signedOut`, and encodes back to `"kind":"none"`
    func testAStoredNoneKindDecodesAsSignedOut() throws {
        let data = Data(#"""
        {"schemaVersion":1,"generation":3,"lastWriteTimestamp":1790000000000,"kind":"none",
         "label":"Acme Corp","username":"alice"}
        """#.utf8)

        guard case .envelope(let decoded) = SessionRecordEnvelope.decode(data) else {
            return XCTFail("a v1 signed-out row must decode")
        }
        XCTAssertEqual(decoded.record, SessionRecord(label: "Acme Corp", username: "alice", kind: .signedOut, credentials: nil))
        XCTAssertEqual(try jsonObject(decoded.encoded())["kind"] as? String, "none")
    }

    /// A record from a newer schema is present and well-formed; calling it corrupt would invite
    /// deleting it, and calling it absent would show sign-in.
    ///
    /// - Given: records with a schema version above the current one, including one whose other fields
    ///   a v1 reader could not parse
    /// - When: they are decoded
    /// - Then:
    ///    - each is `unsupportedSchema` with its version, not `corrupt`
    func testHigherSchemaVersionIsUnsupportedNotCorrupt() {
        XCTAssertEqual(SessionRecordEnvelope.decode(StorageFixtures.futureSchemaRecord), .unsupportedSchema(version: 2))
        XCTAssertEqual(
            SessionRecordEnvelope.decode(Data(#"{"schemaVersion":9,"generation":1,"lastWriteTimestamp":0,"kind":"none"}"#.utf8)),
            .unsupportedSchema(version: 9)
        )
    }

    /// - Given: blobs that are not a record of any version
    /// - When: they are decoded
    /// - Then:
    ///    - each is `corrupt`
    func testMalformedDataIsCorrupt() {
        let cases: [String] = [
            "not json",
            "[1,2,3]",
            #"{"generation":1}"#,
            #"{"schemaVersion":"1"}"#,
            #"{"schemaVersion":0,"generation":1,"lastWriteTimestamp":0,"kind":"none"}"#,
            #"{"schemaVersion":1,"lastWriteTimestamp":0,"kind":"none"}"#,
            #"{"schemaVersion":1,"generation":-1,"lastWriteTimestamp":0,"kind":"none"}"#,
            #"{"schemaVersion":1,"generation":1,"lastWriteTimestamp":0,"kind":"admin"}"#,
            #"{"schemaVersion":1,"generation":1,"lastWriteTimestamp":0,"kind":"guest","credentials":"***"}"#
        ]
        for json in cases {
            XCTAssertEqual(SessionRecordEnvelope.decode(Data(json.utf8)), .corrupt, json)
        }
        XCTAssertEqual(SessionRecordEnvelope.decode(Data()), .corrupt)
    }
}

private extension SessionRecordEnvelope.CodingKeys {
    static let allRawValues: [String] = [
        Self.schemaVersion, .generation, .lastWriteTimestamp, .label, .username, .userId, .kind, .credentials
    ].map(\.rawValue)
}
