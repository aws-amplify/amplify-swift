//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `.default`'s sidecar and challenge items belong to the plugin's session: the plugin's keychain
/// module recognises exactly the accounts the client writes them under, so its access-group migration moves
/// them with the plugin's record, and it recognises no named session's account.
final class DefaultSessionItemAccountTests: XCTestCase {

    private let namespaces: [PoolNamespace] = [
        .userPool("us-east-1_AbCdEf123"),
        .identityPool("us-east-1:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88"),
        .userPoolAndIdentityPool(userPoolId: "us-east-1_AbCdEf123", identityPoolId: "us-east-1:0e3c1a52-7f0b-4a55-9d7a-2b6f3c1d9e88")
    ]

    /// `.default`'s meta and challenge accounts move with the plugin's session; no named session's does.
    ///
    /// - Given: for each of the three namespace shapes, `.default`'s sidecar account
    ///   (`SessionRecordKey.metaAccount(in:)`, `amplify.1.<ns>.$default.meta`) and challenge account, `.default`'s session account (the
    ///   development leftover), and a named session's session and challenge accounts
    /// - When:
    ///    - each is classified by `SessionRecordAccount.isDefaultSessionItem`
    /// - Then:
    ///    - the sidecar and challenge accounts are default-session items, so the plugin's migration moves them
    ///    - `.default`'s session account and every named session's account are not
    ///
    func testMetaAndChallengeAccountsMoveWithThePluginsSession() throws {
        let work = try SessionID.named("work")
        for namespace in namespaces {
            let meta = SessionRecordKey.metaAccount(in: namespace)
            let challenge = SessionRecordKey.account(for: .default, in: namespace, kind: .challenge)
            XCTAssertTrue(SessionRecordAccount.isDefaultSessionItem(meta), meta)
            XCTAssertTrue(SessionRecordAccount.isDefaultSessionItem(challenge), challenge)

            let others = [SessionRecordKey.account(for: .default, in: namespace, kind: .session)]
                + SessionRecordKey.Kind.allCases.map { SessionRecordKey.account(for: work, in: namespace, kind: $0) }
                + ["amplify.\(SessionRecordKey.schemaVersion).\(namespace.keyComponent).\(work.stringValue).meta"]
            for account in others {
                XCTAssertFalse(SessionRecordAccount.isDefaultSessionItem(account), account)
                XCTAssertTrue(SessionRecordAccount.isClientSessionRecord(account), account)
            }
        }
    }
}
