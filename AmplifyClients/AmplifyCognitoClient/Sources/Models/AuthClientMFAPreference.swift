//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Options for `AmplifyCognitoClient.verifyTOTPSetup(code:options:)`.
///
/// The client's counterpart of Amplify core's `VerifyTOTPSetupRequest.Options` with the plugin's
/// `VerifyTOTPSetupOptions` folded in.
@_spi(AmplifyExperimental)
public struct AuthClientVerifyTOTPSetupOptions {

    /// The name to give the TOTP device.
    public var friendlyDeviceName: String?

    public init(friendlyDeviceName: String? = nil) {
        self.friendlyDeviceName = friendlyDeviceName
    }
}

extension AuthClientVerifyTOTPSetupOptions: Equatable {}

extension AuthClientVerifyTOTPSetupOptions: Sendable {}

/// How `AmplifyCognitoClient.updateMFAPreference(sms:totp:email:)` sets one MFA type.
///
/// Mirrors the plugin's `MFAPreference` case for case.
@_spi(AmplifyExperimental)
public enum AuthClientMFAPreference {

    /// Turns the type off.
    case disabled

    /// Turns the type on, keeping whether it is the preferred one.
    case enabled

    /// Turns the type on and makes it the preferred one.
    case preferred

    /// Turns the type on, and not as the preferred one.
    case notPreferred
}

extension AuthClientMFAPreference: Equatable {}

extension AuthClientMFAPreference: Sendable {}

/// The signed-in user's MFA settings, as `AmplifyCognitoClient.fetchMFAPreference()` returns them.
///
/// Mirrors the plugin's `UserMFAPreference`.
@_spi(AmplifyExperimental)
public struct AuthClientUserMFAPreference {

    /// The MFA types turned on for the user, or `nil` if none is.
    public let enabled: Set<AuthClientMFAType>?

    /// The user's preferred MFA type, if any.
    public let preferred: AuthClientMFAType?

    /// Public so an app can build one for a test double; the client builds its own.
    public init(enabled: Set<AuthClientMFAType>?, preferred: AuthClientMFAType?) {
        self.enabled = enabled
        self.preferred = preferred
    }
}

extension AuthClientUserMFAPreference: Equatable {}

extension AuthClientUserMFAPreference: Sendable {}
