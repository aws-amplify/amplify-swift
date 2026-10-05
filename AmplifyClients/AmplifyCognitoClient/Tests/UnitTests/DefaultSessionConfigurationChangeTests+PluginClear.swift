//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The plugin applying a configuration change itself, before any `.default` restore: when it deletes the old
/// configuration's login, it also removes `.default`'s sidecar and interrupted sign-in under the old namespace, as the
/// client does on the same change, so the client lists no signed-out row for a login nobody signed out of. A carry
/// keeps them, as it keeps the login.
extension DefaultSessionConfigurationChangeTests {

    // MARK: - The plugin's clear

    /// A plugin clear leaves the client no signed-out row under the old configuration.
    ///
    /// - Given: the plugin under user pool A, holding alice, labelled through the client, with an interrupted sign-in
    ///   saved for `.default` under A
    /// - When: the plugin's store starts under user pool B, before any client restores
    /// - Then:
    ///    - A's record, A's sidecar and A's interrupted sign-in are deleted
    ///    - listed under A, including signed-out sessions, there is no row: no signed-out row is left for a login
    ///      alice never signed out of
    func testPluginClear_leavesNoSignedOutRowUnderTheOldConfiguration() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.both)
        var labelled: AmplifyCognitoClient? = makeClient(ChangeConfigs.both)
        try await labelled?.setSessionLabel("Work")
        labelled = nil
        await harness.waitForBaseline()
        let oldSidecar = SessionRecordKey.metaAccount(in: ChangeConfigs.both.poolNamespace)
        let oldChallenge = SessionRecordKey.account(for: .default, in: ChangeConfigs.both.poolNamespace, kind: .challenge)
        harness.keychain.put(Data("an interrupted sign-in".utf8), oldChallenge)
        XCTAssertNotNil(harness.keychain.value(oldSidecar))

        pluginStore(ChangeConfigs.otherUserPool)

        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
        XCTAssertNil(harness.keychain.value(oldSidecar))
        XCTAssertNil(harness.keychain.value(oldChallenge))
        let rowsBack = try await listed(ChangeConfigs.both, includingSignedOut: true)
        XCTAssertEqual(rowsBack, [])
        let rowsThere = try await listed(ChangeConfigs.otherUserPool, includingSignedOut: true)
        XCTAssertEqual(rowsThere, [])
    }

    /// A plugin carry keeps the old configuration's row, with its label.
    ///
    /// - Given: the plugin under a user-pool-only configuration, holding alice, labelled through the client
    /// - When: the plugin's store starts with an identity pool added under the same user pool, app client and region
    ///   (a carry), before any client restores
    /// - Then:
    ///    - the old record and its sidecar are kept
    ///    - listed under the old configuration, `.default` is alice's row, with its label
    func testPluginCarry_keepsTheRowUnderTheOldConfiguration() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        var labelled: AmplifyCognitoClient? = makeClient(ChangeConfigs.userPoolOnly)
        try await labelled?.setSessionLabel("Work")
        labelled = nil
        await harness.waitForBaseline()
        let oldSidecar = SessionRecordKey.metaAccount(in: ChangeConfigs.userPoolOnly.poolNamespace)
        let sidecar = try XCTUnwrap(harness.keychain.value(oldSidecar))

        pluginStore(ChangeConfigs.both)

        XCTAssertNotNil(harness.keychain.value(account(ChangeConfigs.userPoolOnly)))
        XCTAssertEqual(harness.keychain.value(oldSidecar), sidecar)
        let rowsBack = try await listed(ChangeConfigs.userPoolOnly, includingSignedOut: true)
        XCTAssertEqual(rowsBack.map(\.sessionId), [.default])
        XCTAssertEqual(rowsBack.first?.username, "alice")
        XCTAssertEqual(rowsBack.first?.label, "Work")
        XCTAssertEqual(rowsBack.first?.kind, .userPoolOnly)
    }

    // MARK: - The accounts

    /// The shared builder the plugin uses names exactly the client's default-session items.
    ///
    /// - Given: a user-pool-only, an identity-pool-only and a two-pool namespace
    /// - When: the shared builder the plugin uses names `.default`'s two items under each
    /// - Then:
    ///    - they are the client's own sidecar and interrupted-sign-in accounts for `.default`, in that order
    func testTheSharedBuilderNamesTheClientsDefaultSessionItems() {
        let namespaces: [PoolNamespace] = [
            .userPool("us-east-1_Pool"),
            .identityPool("us-east-1:00000000-0000-0000-0000-000000000001"),
            .userPoolAndIdentityPool(userPoolId: "us-east-1_Pool", identityPoolId: "us-east-1:00000000-0000-0000-0000-000000000001")
        ]
        for namespace in namespaces {
            let accounts = SessionRecordAccount.defaultSessionItemAccounts(poolNamespace: namespace.keyComponent)
            XCTAssertEqual(accounts, [
                SessionRecordKey.metaAccount(in: namespace),
                SessionRecordKey.account(for: .default, in: namespace, kind: .challenge)
            ])
            XCTAssertTrue(accounts.allSatisfy(SessionRecordAccount.isDefaultSessionItem))
        }
    }
}
