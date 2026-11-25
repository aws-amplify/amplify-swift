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
public struct AmplifyCognitoClientVerifyTOTPSetupOptions {

    /// The name to give the TOTP device.
    public let friendlyDeviceName: String?

    public init(friendlyDeviceName: String? = nil) {
        self.friendlyDeviceName = friendlyDeviceName
    }
}

extension AmplifyCognitoClientVerifyTOTPSetupOptions: Equatable {}

extension AmplifyCognitoClientVerifyTOTPSetupOptions: Sendable {}

/// How `AmplifyCognitoClient.updateMFAPreference(sms:totp:email:)` sets one MFA type.
///
/// Mirrors the plugin's `MFAPreference` case for case.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AmplifyCognitoClientMFAPreference {

    /// Turns the type off.
    case disabled

    /// Turns the type on, keeping whether it is the preferred one.
    case enabled

    /// Turns the type on and makes it the preferred one.
    case preferred

    /// Turns the type on, and not as the preferred one.
    case notPreferred
}

extension AmplifyCognitoClientMFAPreference: Equatable {}

extension AmplifyCognitoClientMFAPreference: Sendable {}

/// The signed-in user's MFA settings, as `AmplifyCognitoClient.fetchMFAPreference()` returns them.
///
/// Mirrors the plugin's `UserMFAPreference`.
@_spi(AmplifyExperimental)
public struct AmplifyCognitoClientUserMFAPreference {

    /// The MFA types turned on for the user, or `nil` if none is.
    public let enabled: Set<AmplifyCognitoClientMFAType>?

    /// The user's preferred MFA type, if any.
    public let preferred: AmplifyCognitoClientMFAType?

    /// Public so an app can build one for a test double; the client builds its own.
    public init(enabled: Set<AmplifyCognitoClientMFAType>?, preferred: AmplifyCognitoClientMFAType?) {
        self.enabled = enabled
        self.preferred = preferred
    }
}

extension AmplifyCognitoClientUserMFAPreference: Equatable {}

extension AmplifyCognitoClientUserMFAPreference: Sendable {}
