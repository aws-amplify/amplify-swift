//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A device remembered for the signed-in user.
///
/// Mirrors the plugin's `AWSAuthDevice`. Amplify core's `AuthDevice` is a protocol the plugin's type
/// conforms to; the client has only the concrete type.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientDevice {

    /// The device key.
    public let id: String

    /// The device's name.
    public let name: String

    /// The device's attributes, if Cognito returned any.
    public let attributes: [String: String]?

    /// When the device was first remembered (Cognito's `DeviceCreateDate`), if Cognito returned it.
    public let createdDate: Date?

    /// When the user last signed in on the device (`DeviceLastAuthenticatedDate`), if Cognito returned it.
    public let lastAuthenticatedDate: Date?

    /// When the device's record last changed (`DeviceLastModifiedDate`), if Cognito returned it.
    public let lastModifiedDate: Date?

    /// Public so an app can build one for a test double; the client builds its own.
    public init(
        id: String,
        name: String,
        attributes: [String: String]? = nil,
        createdDate: Date? = nil,
        lastAuthenticatedDate: Date? = nil,
        lastModifiedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.attributes = attributes
        self.createdDate = createdDate
        self.lastAuthenticatedDate = lastAuthenticatedDate
        self.lastModifiedDate = lastModifiedDate
    }
}

extension AmplifyCognitoClientDevice: Equatable {}

extension AmplifyCognitoClientDevice: Sendable {}

/// Options for `AmplifyCognitoClient.fetchDevices(options:)`.
///
/// Empty: here so the call keeps the plugin's shape. The client's counterpart of Amplify core's
/// `AuthFetchDevicesRequest.Options`, which holds only `pluginOptions`; the client has no plugin
/// options.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientFetchDevicesOptions {

    /// No options yet.
    public init() {}
}

extension AmplifyCognitoClientFetchDevicesOptions: Equatable {}

extension AmplifyCognitoClientFetchDevicesOptions: Sendable {}

/// Options for `AmplifyCognitoClient.rememberDevice(options:)`.
///
/// Empty: here so the call keeps the plugin's shape. The client's counterpart of Amplify core's
/// `AuthRememberDeviceRequest.Options`, which holds only `pluginOptions`; the client has no plugin
/// options.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientRememberDeviceOptions {

    /// No options yet.
    public init() {}
}

extension AmplifyCognitoClientRememberDeviceOptions: Equatable {}

extension AmplifyCognitoClientRememberDeviceOptions: Sendable {}

/// Options for `AmplifyCognitoClient.forgetDevice(_:options:)`.
///
/// Empty: here so the call keeps the plugin's shape. The client's counterpart of Amplify core's
/// `AuthForgetDeviceRequest.Options`, which holds only `pluginOptions`; the client has no plugin
/// options.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientForgetDeviceOptions {

    /// No options yet.
    public init() {}
}

extension AmplifyCognitoClientForgetDeviceOptions: Equatable {}

extension AmplifyCognitoClientForgetDeviceOptions: Sendable {}
