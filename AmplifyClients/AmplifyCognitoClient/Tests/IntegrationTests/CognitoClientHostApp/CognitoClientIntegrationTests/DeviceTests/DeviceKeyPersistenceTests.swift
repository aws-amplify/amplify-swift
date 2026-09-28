//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Parity DV-4 … DV-9: the plugin's `DeviceKeyPersistenceIntegrationTests`, on U-DEF
/// (device tracking "always remember", SRP and password flows) with a fresh user each.
///
/// Once a device is registered, later sign-ins reuse its key rather than registering a new device, whatever
/// the flow: the device record is kept per user on this device, so a second session of the
/// same user presents the same key, and another user's session never does.
final class DeviceKeyPersistenceTests: DeviceTestCase {

    /// DV-4, `testDeviceKeyPersistsAcrossSignOutSignIn`: the device id is the same after a sign-out and an
    /// SRP sign-in, and a second session of the same user presents it too.
    ///
    /// - Given: a fresh user signed in with SRP, who called rememberDevice
    /// - When:
    ///    - the user signs out and signs back in with SRP on the same session
    ///    - then signs in with SRP on a second session
    ///    - and a second fresh user signs in on a third session
    ///    - then the first user signs out and back in on the first session
    /// - Then:
    ///    - fetchDevices lists the one device each time, with the same id
    ///    - the second session's access token carries the same device key
    ///    - the other user's session presents a different device key, and lists no device of the first
    ///    - the first user, signing in again after it, still presents the same key and lists the one device
    ///
    func testDeviceKeyPersistsAcrossSignOutSignIn() async throws {
        let user = try await makeFreshUser(on: .standard)
        let client = try makeClient("dv-4", pool: .standard)
        try await signInToDone(client, user, flow: .userSRP)

        try await client.rememberDevice()
        let firstDeviceKey = try await thisDeviceKey(client)
        assertOnlyThisDevice(try await client.fetchDevices(), firstDeviceKey, "after the first sign-in")

        _ = try await client.signOut()
        try await signInToDone(client, user, flow: .userSRP)

        let secondDeviceKey = try await thisDeviceKey(client)
        XCTAssertTrue(secondDeviceKey == firstDeviceKey, "the device key changed across sign-out and sign-in")
        assertOnlyThisDevice(try await client.fetchDevices(), firstDeviceKey, "after re-sign-in, not a duplicate")

        // A second session of the same user shares the per-user device record.
        let secondSession = try makeClient("dv-4-second", pool: .standard)
        try await signInToDone(secondSession, user, flow: .userSRP)
        let secondSessionKey = try await thisDeviceKey(secondSession)
        XCTAssertTrue(secondSessionKey == firstDeviceKey, "a second session of the same user registered another device")
        assertOnlyThisDevice(try await secondSession.fetchDevices(), firstDeviceKey, "from the second session")

        // Another user's session on this device never presents the first user's device.
        let otherUser = try await makeFreshUser(on: .standard)
        let otherSession = try makeClient("dv-4-other", pool: .standard)
        try await signInToDone(otherSession, otherUser, flow: .userSRP)
        let otherDeviceKey = try await thisDeviceKey(otherSession)
        XCTAssertTrue(otherDeviceKey != firstDeviceKey, "another user's session presented the first user's device")
        let otherDevices = try await otherSession.fetchDevices().map(\.id)
        XCTAssertFalse(otherDevices.contains(firstDeviceKey), "another user lists the first user's device")

        // The other user's sign-in left the first user's device record alone.
        _ = try await client.signOut()
        try await signInToDone(client, user, flow: .userSRP)
        let afterOtherUserKey = try await thisDeviceKey(client)
        XCTAssertTrue(afterOtherUserKey == firstDeviceKey, "another user's sign-in changed the first user's device key")
        assertOnlyThisDevice(try await client.fetchDevices(), firstDeviceKey, "after the other user's sign-in")
    }

    /// DV-5, `testDeviceKeyPersistsFromUserPasswordToUserSRP`: the key survives a change of flow.
    ///
    /// - Given: a fresh user who signed in with USER_PASSWORD_AUTH and called rememberDevice
    /// - When:
    ///    - the user signs out and signs back in with USER_SRP_AUTH
    /// - Then:
    ///    - fetchDevices lists the same single device, not a new one
    ///
    func testDeviceKeyPersistsFromUserPasswordToUserSRP() async throws {
        try await assertDeviceKeyPersists(from: .userPassword, to: [.userSRP], tag: "dv-5")
    }

    /// DV-6, `testDeviceKeyPersistsFromUserSRPToUserPassword`: the reverse.
    ///
    /// - Given: a fresh user who signed in with USER_SRP_AUTH and called rememberDevice
    /// - When:
    ///    - the user signs out and signs back in with USER_PASSWORD_AUTH
    /// - Then:
    ///    - fetchDevices lists the same single device, not a new one
    ///
    func testDeviceKeyPersistsFromUserSRPToUserPassword() async throws {
        try await assertDeviceKeyPersists(from: .userSRP, to: [.userPassword], tag: "dv-6")
    }

    /// DV-7, `testDeviceKeyStableAcrossAlternatingAuthFlows`: four alternating cycles keep one device.
    ///
    /// - Given: a fresh user who signed in with USER_PASSWORD_AUTH and called rememberDevice
    /// - When:
    ///    - the user alternates SRP → password → SRP → password, signing out before each
    /// - Then:
    ///    - fetchDevices lists the same single device after every cycle
    ///
    func testDeviceKeyStableAcrossAlternatingAuthFlows() async throws {
        try await assertDeviceKeyPersists(
            from: .userPassword,
            to: [.userSRP, .userPassword, .userSRP, .userPassword],
            tag: "dv-7"
        )
    }

    /// DV-8, `testTokenRefreshSucceedsWithDeviceTracking`: a forced refresh with a remembered device.
    ///
    /// - Given: a fresh user signed in with USER_SRP_AUTH, with the device remembered
    /// - When:
    ///    - fetchAuthSession is called with forceRefresh
    /// - Then:
    ///    - the session holds new, valid tokens and is still signed in
    ///
    func testTokenRefreshSucceedsWithDeviceTracking() async throws {
        let user = try await makeFreshUser(on: .standard)
        let client = try makeClient("dv-8", pool: .standard)
        try await signInToDone(client, user, flow: .userSRP)
        try await client.rememberDevice()

        try await forceRefresh(client, "the refresh with device tracking")
    }

    /// DV-9, `testConsecutiveTokenRefreshesSucceedWithDeviceTracking`: two consecutive refreshes.
    ///
    /// - Given: a fresh user signed in with USER_SRP_AUTH, with the device remembered
    /// - When:
    ///    - fetchAuthSession is called with forceRefresh twice
    /// - Then:
    ///    - both refreshes succeed: the device record's username survives the first
    ///
    func testConsecutiveTokenRefreshesSucceedWithDeviceTracking() async throws {
        let user = try await makeFreshUser(on: .standard)
        let client = try makeClient("dv-9", pool: .standard)
        try await signInToDone(client, user, flow: .userSRP)
        try await client.rememberDevice()

        try await forceRefresh(client, "the first refresh")
        try await forceRefresh(client, "the second refresh")
    }

    // MARK: Helpers

    /// Signs a fresh user in with `first`, remembers the device, then for each of `then` signs out and
    /// back in with that flow, checking after each that the one listed device is the first one.
    private func assertDeviceKeyPersists(
        from first: AuthClientAuthFlowType,
        to then: [AuthClientAuthFlowType],
        tag: String
    ) async throws {
        let user = try await makeFreshUser(on: .standard)
        let client = try makeClient(tag, pool: .standard)
        try await signInToDone(client, user, flow: first)

        try await client.rememberDevice()
        let originalDeviceKey = try await thisDeviceKey(client)
        assertOnlyThisDevice(try await client.fetchDevices(), originalDeviceKey, "after the first sign-in")

        for (index, flow) in then.enumerated() {
            _ = try await client.signOut()
            try await signInToDone(client, user, flow: flow)
            let cycle = "cycle \(index + 1) (\(flow))"
            let deviceKey = try await thisDeviceKey(client)
            XCTAssertTrue(deviceKey == originalDeviceKey, "\(cycle): the device key changed")
            assertOnlyThisDevice(try await client.fetchDevices(), originalDeviceKey, cycle)
        }
    }
}
