//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Parity DV-10 … DV-19: the plugin's `DeviceAliasTokenRefreshIntegrationTests`
/// (#4207), on U-ALIAS: email as the username, device tracking "always remember", 5-minute tokens.
///
/// The user signs in with an email, so the name typed at sign-in differs from the tokens' username (the
/// generated one). The device record is kept under the typed name, and every device operation and refresh
/// must find it there. Each test signs up its own user, so no other device of the user is ever listed;
/// the assertions still identify this session's device by its access token's `device_key` claim, as the
/// plugin suite does on its shared user.
///
/// A fresh user must be confirmed: by the backend's pre-sign-up trigger, or with its sign-up code from the
/// code API its outputs name. Where the file is not the sandbox's, names no code API and the plugin's setup
/// promises no such trigger (the plugin's device-alias backend on CI), every test fails naming the file
/// before any sign-up (`SandboxSignUp.requireNotKnownUnconfirmable`), so it sends no email and leaves no user
/// it could not delete. The plugin's suite reads no code: it signs in one
/// pre-created user from `AWSCognitoAuthPluginDeviceAliasTests-credentials.json`, which the plugin's CI
/// does not download, and it is only in the `AuthGen2IntegrationTests` target, which no CI workflow runs.
final class DeviceAliasTests: DeviceTestCase {

    /// A fresh email-username user, signed in with SRP by email on a new session.
    private func signedInAliasUser(_ tag: String) async throws -> (FreshUser, AmplifyCognitoClient) {
        let user = try await makeFreshUser(on: .emailAlias)
        let client = try makeClient(tag, pool: .emailAlias)
        try await signInToDone(client, user, flow: .userSRP)
        let username = try await client.getCurrentUser().username
        XCTAssertTrue(username != user.username, "the tokens' username is the typed email; the pool should generate one")
        return (user, client)
    }

    // MARK: Token refresh (#4207)

    /// DV-10, `testTokenRefreshSucceedsWithEmailAliasAndDeviceTracking`: a refresh works when the name
    /// typed at sign-in differs from the tokens' username.
    ///
    /// - Given: a fresh user signed in by email (USER_SRP_AUTH); the pool remembers the device
    /// - When:
    ///    - fetchAuthSession is called with forceRefresh
    /// - Then:
    ///    - the session holds new, valid tokens (not "Invalid Refresh Token")
    ///
    func testTokenRefreshSucceedsWithEmailAliasAndDeviceTracking() async throws {
        let (_, client) = try await signedInAliasUser("dv-10")

        try await forceRefresh(client, "the refresh with an email alias and device tracking")
    }

    /// DV-11, `testConsecutiveTokenRefreshesWithEmailAlias`: two refreshes.
    ///
    /// - Given: a fresh user signed in by email (USER_SRP_AUTH)
    /// - When:
    ///    - fetchAuthSession is called with forceRefresh twice
    /// - Then:
    ///    - both succeed: the typed name survives the first refresh
    ///
    func testConsecutiveTokenRefreshesWithEmailAlias() async throws {
        let (_, client) = try await signedInAliasUser("dv-11")

        try await forceRefresh(client, "the first refresh")
        try await forceRefresh(client, "the second refresh")
    }

    /// DV-12, `testTokenRefreshAfterReSignInWithEmailAlias`: a refresh after a sign-out and sign-in.
    ///
    /// - Given: a fresh user who signed in by email, signed out, and signed back in
    /// - When:
    ///    - fetchAuthSession is called with forceRefresh
    /// - Then:
    ///    - the refresh succeeds
    ///
    func testTokenRefreshAfterReSignInWithEmailAlias() async throws {
        let (user, client) = try await signedInAliasUser("dv-12")
        _ = try await client.signOut()
        try await signInToDone(client, user, flow: .userSRP)

        try await forceRefresh(client, "the refresh after re-sign-in")
    }

    // MARK: rememberDevice and forgetDevice

    /// DV-13, `testRememberDeviceSucceedsWithEmailAlias`: remembering finds the device record.
    ///
    /// - Given: a fresh user signed in by email (USER_SRP_AUTH)
    /// - When:
    ///    - rememberDevice is called
    /// - Then:
    ///    - it succeeds, with no "Unable to get device metadata", and this device is listed
    ///
    func testRememberDeviceSucceedsWithEmailAlias() async throws {
        let (_, client) = try await signedInAliasUser("dv-13")

        try await client.rememberDevice()

        let deviceKey = try await thisDeviceKey(client)
        let devices = try await client.fetchDevices()
        XCTAssertGreaterThanOrEqual(devices.count, 1)
        XCTAssertTrue(devices.map(\.id).contains(deviceKey), "this device is not listed after rememberDevice()")
    }

    /// DV-14, `testForgetDeviceSucceedsWithEmailAlias`: forgetting finds the device record.
    ///
    /// - Given: a fresh user signed in by email, with the device remembered
    /// - When:
    ///    - forgetDevice is called
    /// - Then:
    ///    - it succeeds; this device was the only one listed before, and none is listed after
    ///
    func testForgetDeviceSucceedsWithEmailAlias() async throws {
        let (_, client) = try await signedInAliasUser("dv-14")
        try await client.rememberDevice()

        try await assertForgetsThisDevice(client, "forgetDevice()")
    }

    /// DV-15, `testForgetDeviceAfterTokenRefreshWithEmailAlias`: forgetting after a refresh.
    ///
    /// - Given: a fresh user signed in by email, with the device remembered, after a forced refresh
    /// - When:
    ///    - forgetDevice is called
    /// - Then:
    ///    - it succeeds: the typed name survives the refresh; this device was the only one listed before,
    ///      and none is listed after
    ///
    func testForgetDeviceAfterTokenRefreshWithEmailAlias() async throws {
        let (_, client) = try await signedInAliasUser("dv-15")
        try await client.rememberDevice()
        try await forceRefresh(client, "the refresh before forgetting")

        try await assertForgetsThisDevice(client, "forgetDevice after a refresh")
    }

    // MARK: fetchDevices

    /// DV-16, `testFetchDevicesReturnsDetailsWithEmailAlias`: the listed device has its details.
    ///
    /// - Given: a fresh user signed in by email, with the device remembered
    /// - When:
    ///    - fetchDevices is called
    /// - Then:
    ///    - this device is listed with a non-empty id, a creation date and a last-authenticated date
    ///
    func testFetchDevicesReturnsDetailsWithEmailAlias() async throws {
        let (_, client) = try await signedInAliasUser("dv-16")
        try await client.rememberDevice()

        let devices = try await client.fetchDevices()

        XCTAssertGreaterThanOrEqual(devices.count, 1)
        let deviceKey = try await thisDeviceKey(client)
        let device = try XCTUnwrap(devices.first { $0.id == deviceKey }, "this device is not listed")
        XCTAssertFalse(device.id.isEmpty, "the device has no id")
        XCTAssertNotNil(device.createdDate, "the device has no creation date")
        XCTAssertNotNil(device.lastAuthenticatedDate, "the device has no last-authenticated date")
    }

    // MARK: Device persistence

    /// DV-17, `testDevicePersistsAcrossSignOutSignInWithEmailAlias`: the same device after a sign-out and
    /// sign-in.
    ///
    /// - Given: a fresh user signed in by email, with the device remembered
    /// - When:
    ///    - the user signs out and signs back in by email
    /// - Then:
    ///    - the session presents the same device key, and fetchDevices lists it as the one device
    ///
    func testDevicePersistsAcrossSignOutSignInWithEmailAlias() async throws {
        let (user, client) = try await signedInAliasUser("dv-17")
        try await client.rememberDevice()
        let firstDeviceKey = try await thisDeviceKey(client)
        assertOnlyThisDevice(try await client.fetchDevices(), firstDeviceKey, "after the first sign-in")

        _ = try await client.signOut()
        try await signInToDone(client, user, flow: .userSRP)

        let secondDeviceKey = try await thisDeviceKey(client)
        XCTAssertTrue(secondDeviceKey == firstDeviceKey, "the device key changed across sign-out and sign-in")
        assertOnlyThisDevice(try await client.fetchDevices(), firstDeviceKey, "after re-sign-in")
    }

    /// DV-18, `testTokenRefreshAfterDevicePersistenceWithEmailAlias`: a refresh after the device persisted.
    ///
    /// - Given: a fresh user who signed in by email, remembered the device, signed out and signed back in
    /// - When:
    ///    - fetchAuthSession is called with forceRefresh
    /// - Then:
    ///    - the refresh succeeds: the device record is still found after the sign-out and sign-in
    ///
    func testTokenRefreshAfterDevicePersistenceWithEmailAlias() async throws {
        let (user, client) = try await signedInAliasUser("dv-18")
        try await client.rememberDevice()
        _ = try await client.signOut()
        try await signInToDone(client, user, flow: .userSRP)

        try await forceRefresh(client, "the refresh after re-sign-in")
    }

    // MARK: Full lifecycle

    /// DV-19, `testFullDeviceLifecycleWithEmailAlias`: remember → fetch → refresh → forget → fetch.
    ///
    /// - Given: a fresh user signed in by email
    /// - When:
    ///    - the device is remembered, listed, the tokens refreshed, and the device forgotten
    /// - Then:
    ///    - each step succeeds; this device is the only one listed before the forget, and none after
    ///
    func testFullDeviceLifecycleWithEmailAlias() async throws {
        let (_, client) = try await signedInAliasUser("dv-19")

        try await client.rememberDevice()
        let deviceKey = try await thisDeviceKey(client)
        let devicesAfterRemember = try await client.fetchDevices()
        XCTAssertGreaterThanOrEqual(devicesAfterRemember.count, 1)
        XCTAssertTrue(devicesAfterRemember.map(\.id).contains(deviceKey), "this device is not listed after rememberDevice()")

        try await forceRefresh(client, "the refresh mid-lifecycle")

        try await assertForgetsThisDevice(client, "forgetDevice with an email alias")
    }
}
