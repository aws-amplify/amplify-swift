//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Devices, with the plugin's semantics, for this session's user only.
///
/// Each call uses this session's access token, refreshed first if it needs it, and never changes the
/// session's saved record or disturbs a sign-in waiting on a challenge. The device records on this device
/// stay per user, at the plugin's keys, so two sessions holding the same user share them, and a session of
/// another user never sees them.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// The signed-in user's remembered devices.
    ///
    /// - Throws: `AuthClientError.notSignedIn` for a signed-out, guest or federated session, or while a
    ///   sign-in waits on a challenge; `.sessionExpired` when the refresh token is no longer valid;
    ///   `.storageUnavailable` if storage could not be read; `.configuration` without a user pool;
    ///   `.notAuthorized` or `.service` as Cognito answers; `.unknown` if Cognito answers without a device
    ///   list.
    func fetchDevices() async throws -> [AuthClientDevice] {
        let core = core
        return try await core.signedInOperation("fetch the devices") { engine, payload in
            try await engine.fetchDevices(payload)
        }
    }

    /// Remembers this device for the signed-in user.
    ///
    /// - Throws: `AuthClientError.notSignedIn`, `.sessionExpired`, `.configuration`, `.notAuthorized` and
    ///   `.service` as `fetchDevices()`; `.storageUnavailable` if storage, including this device's device
    ///   record, could not be read; `.unknown` ("Unable to get device metadata") when this device holds no
    ///   device record for the user, as the plugin does (the pool does not track devices, or this device
    ///   has not signed in since tracking was enabled). No request is sent then.
    func rememberDevice() async throws {
        let core = core
        try await core.signedInOperation("remember the device") { engine, payload in
            try await engine.rememberDevice(payload)
        }
    }

    /// Forgets a device for the signed-in user.
    ///
    /// - Parameter device: The device to forget, from `fetchDevices()`; `nil` for this device.
    /// - Throws: `AuthClientError.notSignedIn`, `.sessionExpired`, `.storageUnavailable`, `.configuration`,
    ///   `.notAuthorized` and `.service` as `fetchDevices()`. For this device (`nil`), also as
    ///   `rememberDevice()`: `.storageUnavailable` if its device record could not be read, and `.unknown`
    ///   ("Unable to get device metadata") when there is none. Forgetting keeps the record on this device,
    ///   as the plugin does.
    func forgetDevice(_ device: AuthClientDevice? = nil) async throws {
        let deviceId = device?.id
        let core = core
        try await core.signedInOperation("forget the device") { engine, payload in
            try await engine.forgetDevice(payload, deviceId: deviceId)
        }
    }
}
