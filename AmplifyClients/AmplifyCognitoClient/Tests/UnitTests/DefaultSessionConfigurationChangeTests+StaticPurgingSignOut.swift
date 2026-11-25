//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

// MARK: - The static signOutStoredSession, purging

extension DefaultSessionConfigurationChangeTests {

    /// The purge of a static sign-out removes this configuration's record only. The login it was carried from is
    /// signed out, not deleted, so until `.default` restores under this configuration its signed-out row is still
    /// carried here, as a static purge's is (the README's "Changing the configuration").
    ///
    /// - Given: alice's labelled record under X (user pool only), recorded as the configuration the app last ran
    ///   with, and no restore under Y (X with an identity pool added)
    /// - When: `signOutStoredSession(.default)` runs under Y with `purgeStoredSession`, then the saved sessions are
    ///   listed under Y, signed-out rows included
    /// - Then:
    ///    - the result is `.complete`, with alice's tokens revoked once
    ///    - Y's record is deleted; X's holds `{"noCredentials":{}}`, and `authConfiguration` still names X
    ///    - the listing under Y shows alice's signed-out row with her label: what a restore under Y will carry
    func testStaticPurgingSignOutUnderACarryingConfiguration_leavesTheSignedOutRowItCarriedFrom() async throws {
        let before = try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        var labelled: AmplifyCognitoClient? = makeClient(ChangeConfigs.userPoolOnly)
        try await labelled?.setSessionLabel("Work")
        labelled = nil
        await harness.waitForBaseline()

        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: ChangeConfigs.both,
            accessGroup: nil,
            options: AuthClientSignOutOptions(purgeStoredSession: true),
            dependencies: dependencies
        )
        let rows = try await listed(ChangeConfigs.both, includingSignedOut: true)

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [before])
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.userPoolOnly)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.userPoolOnly))
        XCTAssertEqual(rows, [StoredSession(sessionId: .default, label: "Work", user: AuthClientUser(username: "alice", userId: "sub-alice"), kind: .signedOut, state: .signedOut)])
    }
}
