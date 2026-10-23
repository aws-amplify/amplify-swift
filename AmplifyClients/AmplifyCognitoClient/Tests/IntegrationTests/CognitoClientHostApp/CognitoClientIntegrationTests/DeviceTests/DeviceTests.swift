//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Parity DV-1 … DV-3: the plugin's `AuthFetchDeviceTests`,
/// `AuthRememberDeviceTests` and `AuthForgetDeviceTests`, on U-DEF (device tracking "always remember")
/// with a fresh user each.
final class DeviceTests: DeviceTestCase {

    /// DV-1, `AuthFetchDeviceTests.testSuccessfulFetchDevices`: fetching devices after sign-in lists this
    /// device, with its details.
    ///
    /// - Given: a fresh user signed in on U-DEF, which remembers every device
    /// - When:
    ///    - I invoke fetchDevices
    /// - Then:
    ///    - exactly one device is listed, this session's, with a name, attributes and all three dates
    ///
    func testSuccessfulFetchDevices() async throws {
        let user = try await makeFreshUser(on: .standard)
        let client = try makeClient("dv-1", pool: .standard)
        try await signInToDone(client, user)

        let devices = try await client.fetchDevices()

        let deviceKey = try await thisDeviceKey(client)
        assertOnlyThisDevice(devices, deviceKey, "after sign-in")
        let device = try XCTUnwrap(devices.first)
        XCTAssertFalse(device.name.isEmpty)
        XCTAssertFalse(device.id.isEmpty)
        XCTAssertEqual(device.attributes?.isEmpty, false)
        XCTAssertNotNil(device.createdDate)
        XCTAssertNotNil(device.lastAuthenticatedDate)
        XCTAssertNotNil(device.lastModifiedDate)
    }

    /// DV-2, `AuthRememberDeviceTests.testSuccessfulRememberDevice`: after remembering, the list contains
    /// this device.
    ///
    /// - Given: a fresh user signed in on U-DEF
    /// - When:
    ///    - I invoke rememberDevice followed by fetchDevices
    /// - Then:
    ///    - rememberDevice succeeds, and the list contains this session's device, with its details
    ///
    func testSuccessfulRememberDevice() async throws {
        let user = try await makeFreshUser(on: .standard)
        let client = try makeClient("dv-2", pool: .standard)
        try await signInToDone(client, user)

        try await client.rememberDevice()
        let devices = try await client.fetchDevices()

        let deviceKey = try await thisDeviceKey(client)
        let device = try XCTUnwrap(devices.first { $0.id == deviceKey }, "this device is not listed")
        XCTAssertGreaterThan(devices.count, 0)
        XCTAssertFalse(device.name.isEmpty)
        XCTAssertEqual(device.attributes?.isEmpty, false)
        XCTAssertNotNil(device.createdDate)
        XCTAssertNotNil(device.lastAuthenticatedDate)
        XCTAssertNotNil(device.lastModifiedDate)
    }

    /// DV-3, `AuthForgetDeviceTests.testSuccessfulForgetDevice`: remember, forget, then the list is empty.
    ///
    /// - Given: a fresh user signed in on U-DEF
    /// - When:
    ///    - I invoke rememberDevice, followed by forgetDevice and fetchDevices
    /// - Then:
    ///    - both succeed, and fetchDevices lists no device
    ///
    func testSuccessfulForgetDevice() async throws {
        let user = try await makeFreshUser(on: .standard)
        let client = try makeClient("dv-3", pool: .standard)
        try await signInToDone(client, user)

        try await client.rememberDevice()
        try await client.forgetDevice()
        let devices = try await client.fetchDevices()

        XCTAssertEqual(devices.count, 0)
    }
}
