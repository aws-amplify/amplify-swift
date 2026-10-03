//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

final class SessionRecordKeyTests: XCTestCase {

    private let userPoolId = "us-east-1_AbCdEf123"
    private let identityPoolId = "us-east-1:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88"

    /// - Given: each of the three configuration shapes
    /// - When: a session account is generated
    /// - Then:
    ///    - it is `amplify.1.<poolNamespace>.<sessionId>.session`, with the namespace exactly as the
    ///      plugin renders it
    func testAccountFormatForEachConfigurationShape() throws {
        let work = try SessionID.named("work")
        XCTAssertEqual(
            SessionRecordKey.account(for: work, in: .userPool(userPoolId), kind: .session),
            "amplify.1.\(userPoolId).work.session"
        )
        XCTAssertEqual(
            SessionRecordKey.account(for: work, in: .identityPool(identityPoolId), kind: .session),
            "amplify.1.\(identityPoolId).work.session"
        )
        XCTAssertEqual(
            SessionRecordKey.account(
                for: work,
                in: .userPoolAndIdentityPool(userPoolId: userPoolId, identityPoolId: identityPoolId),
                kind: .challenge
            ),
            "amplify.1.\(userPoolId).\(identityPoolId).work.challenge"
        )
    }

    /// `.default`'s session record is the plugin's own account; the `$default` v1 session account is a
    /// development build's leftover, distinct from it.
    ///
    /// - Given: a pool namespace
    /// - When: the plugin's account and the default session's v1 session account are generated
    /// - Then:
    ///    - the plugin's account matches the plugin's format, is what `.default`'s store reads and writes, and
    ///      differs from every v1 account
    func testPluginSessionAccountMatchesThePluginAndIsDefaultsRecord() throws {
        let namespace = PoolNamespace.userPool(userPoolId)
        XCTAssertEqual(SessionRecordKey.pluginSessionAccount(in: namespace), "amplify.\(userPoolId).session")
        XCTAssertNil(SessionRecordKey.parse(SessionRecordKey.pluginSessionAccount(in: namespace)))
        XCTAssertNotEqual(
            SessionRecordKey.pluginSessionAccount(in: namespace),
            SessionRecordKey.account(for: .default, in: namespace, kind: .session)
        )
        let store = TestKeychain().recordStore(for: SessionStorageNamespace(pools: namespace, accessGroup: nil))
        XCTAssertEqual(store.sessionAccount(for: .default), "amplify.\(userPoolId).session")
        XCTAssertNil(try store.pluginSessionAccount(for: SessionID.named("work")))
        XCTAssertEqual(
            SessionRecordKey.account(for: .default, in: namespace, kind: .session),
            "amplify.1.\(userPoolId).$default.session"
        )
    }

    /// Segment counts differ between shapes, so a parser that splits by arity would misread one of
    /// them. Every generated account must parse back to exactly what produced it.
    ///
    /// - Given: every configuration shape × named, minted and sentinel IDs × both kinds
    /// - When: an account is generated and then parsed
    /// - Then:
    ///    - the parse recovers the namespace component, session ID and kind
    func testParseRoundTripsEveryShape() throws {
        let namespaces: [PoolNamespace] = [
            .userPool(userPoolId),
            .identityPool(identityPoolId),
            .userPoolAndIdentityPool(userPoolId: userPoolId, identityPoolId: identityPoolId)
        ]
        let ids = [try SessionID.named("work"), try SessionID.named("a-b_c"), .new(), .default]
        for namespace in namespaces {
            for id in ids {
                for kind in SessionRecordKey.Kind.allCases {
                    let account = SessionRecordKey.account(for: id, in: namespace, kind: kind)
                    XCTAssertEqual(
                        SessionRecordKey.parse(account),
                        .init(namespaceComponent: namespace.keyComponent, sessionId: id, kind: kind),
                        account
                    )
                }
            }
        }
    }

    /// Listing runs over the whole keychain service, which holds far more than session records.
    /// Every other kind of item must be ignored rather than misread as a session.
    ///
    /// - Given: the plugin's legacy record, device metadata and ASF keys, the stored configuration,
    ///   a future schema version, and malformed v1 lookalikes
    /// - When: parsed
    /// - Then:
    ///    - none is recognised as a session record
    func testParseIgnoresEverythingElseInTheService() {
        let notSessionRecords = [
            "amplify.\(userPoolId).session",                                    // plugin's legacy record
            "amplify.\(userPoolId).\(identityPoolId).session",                   // legacy, both pools
            "amplify.\(userPoolId).alice.deviceMetadata",                        // per-user device record
            "amplify.\(userPoolId).alice.deviceASF",                             // ASF device id
            "authConfiguration",                                                 // stored configuration
            "amplify.2.\(userPoolId).work.session",                              // future schema
            "amplify.1.\(userPoolId).work.tokens",                               // unknown kind
            "amplify.1.work.session",                                            // no namespace
            "amplify.1.\(userPoolId).bad$id.session",                            // invalid session id
            "amplify.1.\(userPoolId)..session",                                  // empty session id
            "amplify.1."                                                         // prefix only
        ]
        for account in notSessionRecords {
            XCTAssertNil(SessionRecordKey.parse(account), account)
        }
    }
}
