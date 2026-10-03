//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAmplifyKeychain
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `.default`'s sidecar, `DefaultSessionMeta`: its frozen format, its account, and the rules binding it to a user.
final class DefaultSessionMetaTests: XCTestCase {

    private static let userPoolId = "us-east-1_AbCdEf123"
    private static let identityPoolId = "us-east-1:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88"
    private static let namespaces: [PoolNamespace] = [
        .userPool(userPoolId),
        .identityPool(identityPoolId),
        .userPoolAndIdentityPool(userPoolId: userPoolId, identityPoolId: identityPoolId)
    ]

    /// 1790000000123 ms after the epoch.
    private static let timestamp = Date(timeIntervalSince1970: 1_790_000_000.123)

    private func meta(label: String? = nil, username: String? = nil, userId: String? = nil) -> DefaultSessionMeta {
        DefaultSessionMeta(lastWriteTimestamp: Self.timestamp, label: label, username: username, userId: userId)
    }

    // MARK: Format

    /// - Given: a sidecar with label "Acme Corp", username alice, user ID `sub-1` and timestamp 1790000000123
    /// - When: it is encoded
    /// - Then:
    ///    - the bytes are exactly the frozen form, with sorted keys
    ///    - they decode back to the same sidecar
    func testEncodedFormIsFrozen() throws {
        let sidecar = meta(label: "Acme Corp", username: "alice", userId: "sub-1")

        let encoded = try sidecar.encoded()

        XCTAssertEqual(
            String(decoding: encoded, as: UTF8.self),
            #"{"label":"Acme Corp","lastWriteTimestamp":1790000000123,"schemaVersion":1,"userId":"sub-1","username":"alice"}"#
        )
        XCTAssertEqual(DefaultSessionMeta.decode(encoded), .meta(sidecar))
    }

    /// - Given: a sidecar with no label, username or user ID
    /// - When: it is encoded
    /// - Then:
    ///    - the three keys are omitted, not written as `null`
    ///    - it decodes back with all three `nil`
    func testNilFieldsAreOmitted() throws {
        let sidecar = meta()

        let encoded = try sidecar.encoded()

        XCTAssertEqual(String(decoding: encoded, as: UTF8.self), #"{"lastWriteTimestamp":1790000000123,"schemaVersion":1}"#)
        XCTAssertEqual(DefaultSessionMeta.decode(encoded), .meta(sidecar))
    }

    /// - Given: a sidecar from a newer schema, and bytes that are not a version-1 sidecar
    /// - When: each is decoded
    /// - Then:
    ///    - the newer one is `unsupportedSchema` with its version, even with fields this build cannot read
    ///    - the others are `corrupt`: not JSON, no schema version, schema version 0, a missing timestamp, and a
    ///      field of the wrong type
    func testNewerSchemaIsUnsupportedAndCorruptIsCorrupt() {
        XCTAssertEqual(
            DefaultSessionMeta.decode(Data(#"{"schemaVersion":2,"lastWriteTimestamp":"opaque","label":{"new":true}}"#.utf8)),
            .unsupportedSchema(version: 2)
        )
        let corrupt = [
            "not a sidecar",
            #"{"lastWriteTimestamp":1790000000123}"#,
            #"{"schemaVersion":0,"lastWriteTimestamp":1790000000123}"#,
            #"{"schemaVersion":1}"#,
            #"{"schemaVersion":1,"lastWriteTimestamp":1790000000123,"userId":7}"#
        ]
        for bytes in corrupt {
            XCTAssertEqual(DefaultSessionMeta.decode(Data(bytes.utf8)), .corrupt, bytes)
        }
    }

    /// - Given: a version-1 sidecar with a key this build does not know
    /// - When: it is decoded
    /// - Then:
    ///    - the unknown key is ignored, and the known fields are read
    func testUnknownKeysAreIgnored() {
        let bytes = Data(#"{"future":{"x":1},"label":"Home","lastWriteTimestamp":1790000000123,"schemaVersion":1,"username":"bob"}"#.utf8)

        XCTAssertEqual(DefaultSessionMeta.decode(bytes), .meta(meta(label: "Home", username: "bob")))
    }

    // MARK: Account

    /// - Given: the sidecar account for each of the three namespace shapes
    /// - When: it is parsed as a session record and as a namespace marker
    /// - Then:
    ///    - it is `amplify.1.<poolNamespace>.$default.meta`
    ///    - `SessionRecordKey.parse` and `parseMarker` both return `nil`, so no listing reads it as a session
    ///    - `.default`'s interrupted-sign-in account, its sibling, still parses as a `.challenge` record
    func testMetaAccountIsNeverParsedAsASession() {
        for namespace in Self.namespaces {
            let account = SessionRecordKey.metaAccount(in: namespace)

            XCTAssertEqual(account, "amplify.1.\(namespace.keyComponent).$default.meta")
            XCTAssertNil(SessionRecordKey.parse(account), account)
            XCTAssertNil(SessionRecordKey.parseMarker(account, scope: SessionRecordStore.appMarkerScope), account)
            XCTAssertNil(SessionRecordKey.parseMarker(account, scope: TestKeychain.markerScope), account)
            XCTAssertEqual(
                SessionRecordKey.parse(SessionRecordKey.account(for: .default, in: namespace, kind: .challenge))?.kind,
                .challenge
            )
        }
    }

    /// - Given: the sidecar account for each of the three namespace shapes
    /// - When: it is checked as the plugin's scoped wipe checks it
    /// - Then:
    ///    - it is a client session record, so the scoped wipe leaves it alone. (The plugin's access-group
    ///      migration moves it with `.default`'s other items; that is pinned with the migration.)
    func testMetaAccountIsAClientRecordForThePluginsWipe() {
        for namespace in Self.namespaces {
            let account = SessionRecordKey.metaAccount(in: namespace)

            XCTAssertTrue(SessionRecordAccount.isClientSessionRecord(account), account)
        }
    }

    // MARK: Binding to a user

    /// The label is kept only for the same user, or while the sidecar has no user yet.
    ///
    /// - Given: sidecars bound to alice and bound to no user
    /// - When: each is checked against records holding alice, bob, a guest, nobody (signed out or absent)
    /// - Then:
    ///    - alice's sidecar applies to alice and to a signed-out or absent record only
    ///    - a sidecar with no user applies to every record, so a user who signs in keeps its label
    ///    - after alice signs out, her signing in again keeps the label, and bob's signing in drops it
    func testBindingRules() {
        let alices = meta(label: "Work", username: "alice", userId: "sub-alice")
        let nobodys = meta(label: "Shared iPad")
        let rows: [(String, DefaultSessionMeta, String?, Bool, Bool)] = [
            ("same user", alices, "sub-alice", false, true),
            ("other user", alices, "sub-bob", false, false),
            ("signed out or absent", alices, nil, true, true),
            ("guest record with a user's sidecar", alices, nil, false, false),
            ("no-user sidecar with a guest record", nobodys, nil, false, true),
            ("no-user sidecar with a user record", nobodys, "sub-alice", false, true),
            ("no-user sidecar with a signed-out record", nobodys, nil, true, true),
            ("alice signs in again over her signed-out row", alices, "sub-alice", false, true),
            ("bob signs in over alice's signed-out row", alices, "sub-bob", false, false)
        ]
        for (name, sidecar, recordUser, recordIsSignedOut, expected) in rows {
            XCTAssertEqual(sidecar.applies(toRecordUser: recordUser, recordIsSignedOut: recordIsSignedOut), expected, name)
        }
    }
}
