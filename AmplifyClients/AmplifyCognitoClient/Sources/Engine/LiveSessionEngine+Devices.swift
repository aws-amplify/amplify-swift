//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth

/// Devices, ported from the plugin's `AWSAuthFetchDevicesTask`, `AWSAuthRememberDeviceTask` and
/// `AWSAuthForgetDeviceTask`. Each calls Cognito directly with the payload's access token, as the plugin's
/// tasks do, and never refreshes: the core has already handed over a fresh payload (route 2). None of them
/// reads or writes the session's credentials, and none touches the actor's state, so a pending sign-in is
/// never disturbed.
///
/// **Which device is "this device".** The device key comes from the per-user device record that sign-in
/// wrote (`ConfirmDevice`), read at the plugin's key: `inputUsername ?? username` of the payload's signed-in
/// data, as `AWSAuthRememberDeviceTask.getCurrentUsername()` reads it, so a user who signed in with an email
/// alias finds the record written under that alias (#4207). The record is per user and per namespace, never
/// per session: two sessions of one user share it, and a session of another user reads its
/// own.
extension LiveSessionEngine {

    /// Lists the user's devices (`AWSAuthFetchDevicesTask.fetchDevices`).
    ///
    /// - Throws: Cognito's answer, mapped; `unknown` if Cognito answers without a device list.
    nonisolated func fetchDevices(_ payload: Data) async throws -> [AuthClientDevice] {
        let signedIn = try signedInUser(in: payload)
        let userPool = try deviceUserPool()
        let output = try await Self.mappingServiceErrors {
            try await userPool.listDevices(input: ListDevicesInput(accessToken: signedIn.accessToken))
        }
        guard let devices = output.devices else {
            throw AuthClientError.unknown(
                "Unable to get devices list from response",
                "This is not expected. Retry the operation."
            )
        }
        return devices.map(AuthClientDevice.init)
    }

    /// Marks this device remembered (`AWSAuthRememberDeviceTask.rememberDevice`).
    ///
    /// - Throws: `unknown` ("Unable to get device metadata") when no device record exists for the user, with
    ///   no request sent; otherwise Cognito's answer, mapped.
    nonisolated func rememberDevice(_ payload: Data) async throws {
        let signedIn = try signedInUser(in: payload)
        let userPool = try deviceUserPool()
        let deviceKey = try await currentDeviceKey(for: signedIn.deviceUsername)
        _ = try await Self.mappingServiceErrors {
            try await userPool.updateDeviceStatus(input: UpdateDeviceStatusInput(
                accessToken: signedIn.accessToken,
                deviceKey: deviceKey,
                deviceRememberedStatus: .remembered
            ))
        }
    }

    /// Forgets a device (`AWSAuthForgetDeviceTask.forgetDevice`): `deviceId`, or this device when `nil`. As
    /// in the plugin, the local device record is kept: the next sign-in finds Cognito no longer knows the
    /// key and starts again.
    ///
    /// - Throws: for this device, `unknown` ("Unable to get device metadata") when no device record exists
    ///   for the user, with no request sent; otherwise Cognito's answer, mapped.
    nonisolated func forgetDevice(_ payload: Data, deviceId: String?) async throws {
        let signedIn = try signedInUser(in: payload)
        let userPool = try deviceUserPool()
        let deviceKey: String
        if let deviceId {
            deviceKey = deviceId
        } else {
            deviceKey = try await currentDeviceKey(for: signedIn.deviceUsername)
        }
        _ = try await Self.mappingServiceErrors {
            try await userPool.forgetDevice(input: ForgetDeviceInput(
                accessToken: signedIn.accessToken,
                deviceKey: deviceKey
            ))
        }
    }

    // MARK: Support

    /// What a device operation needs from the payload: its access token, and the username the device
    /// record is kept under.
    struct DeviceOperationUser {
        let accessToken: String
        /// `inputUsername ?? username`: the name sign-in stored the device record under.
        let deviceUsername: String
    }

    /// The payload's user-pool user. The core refuses a session without an access token before the engine
    /// is called (`notSignedIn`), so the throw only guards the seam's contract.
    nonisolated func signedInUser(in payload: Data) throws -> DeviceOperationUser {
        try requireUserPool()
        let signedInData: SignedInData
        switch try Self.credentials(in: payload) {
        case .userPoolOnly(let data), .userPoolAndIdentityPool(let data, _, _):
            signedInData = data
        case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
            throw SessionEngineError.notSignedIn
        }
        return DeviceOperationUser(
            accessToken: signedInData.cognitoUserPoolTokens.accessToken,
            deviceUsername: signedInData.inputUsername ?? signedInData.username
        )
    }

    /// The Cognito user pool the operations call: the session's SDK client, or a test's double.
    nonisolated func deviceUserPool() throws -> any CognitoUserPoolBehavior {
        try EngineResources.required(resources.services.userPool, "user pool")
    }

    /// This device's key, from the user's device record (`DeviceMetadataHelper.getDeviceMetadata`).
    ///
    /// **Diverges from the plugin on a keychain failure.** The plugin's helper logs any read failure and
    /// reports "Unable to get device metadata"; the client's store never reads a keychain failure as absent,
    /// so the failure is rethrown as the store's `storageUnavailable`, which a retry can clear. Only a record
    /// that is absent, `noData` or undecodable gives the plugin's error.
    ///
    /// - Throws: `storageUnavailable` when the keychain could not be read; `unknown` ("Unable to get device
    ///   metadata") when there is no usable record.
    nonisolated func currentDeviceKey(for username: String) async throws -> String {
        let read: DeviceRecordStore.Read<DeviceMetadata>
        do {
            read = try await resources.devices.deviceMetadata(DeviceMetadata.self, for: username)
        } catch {
            resources.logger.error("Unable to read the device metadata", error)
            throw error
        }
        switch read {
        case .value(.metadata(let data)):
            return data.deviceKey
        case .value(.noData):
            break
        case .absent:
            resources.logger.info("No existing device metadata found.", nil)
        case .undecodable:
            resources.logger.error("Unable to decode the stored device metadata", nil)
        }
        throw AuthClientError.unknown(
            "Unable to get device metadata",
            "Enable device tracking on the user pool, sign in on this device, then retry."
        )
    }

    /// Runs one Cognito call, mapping its failure as the plugin does (`AuthError(converting:)`). Anything
    /// else, such as a cancellation, passes through to the core's mapping.
    static func mappingServiceErrors<Output>(_ call: () async throws -> Output) async throws -> Output {
        do {
            return try await call()
        } catch let error as EngineAuthErrorConvertible {
            throw AuthClientError(engine: error.engineError)
        }
    }
}

extension AuthClientDevice {

    /// A listed device as the plugin maps it (`DeviceType.toAWSAuthDevice()`): the key as the id (empty if
    /// missing), the `device_name` attribute as the name (empty if missing), every named attribute, and
    /// Cognito's three dates.
    init(_ device: CognitoIdentityProviderClientTypes.DeviceType) {
        var attributes: [String: String] = [:]
        for attribute in device.deviceAttributes ?? [] {
            if let name = attribute.name, let value = attribute.value {
                attributes[name] = value
            }
        }
        self.init(
            id: device.deviceKey ?? "",
            name: attributes["device_name", default: ""],
            attributes: attributes,
            createdDate: device.deviceCreateDate,
            lastAuthenticatedDate: device.deviceLastAuthenticatedDate,
            lastModifiedDate: device.deviceLastModifiedDate
        )
    }
}
