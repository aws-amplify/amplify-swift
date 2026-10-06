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
public struct AuthClientDevice {

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

extension AuthClientDevice: Equatable {}

extension AuthClientDevice: Sendable {}
