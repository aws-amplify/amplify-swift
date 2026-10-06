//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// TOTP setup and MFA preferences, with the plugin's semantics, for this session's user only.
///
/// Each call uses this session's access token, refreshed first if it needs it, and never changes the
/// session's saved record or disturbs a sign-in waiting on a challenge. As in the plugin, the arguments are
/// not validated here: Cognito answers an empty or malformed code.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// Starts setting up TOTP for the signed-in user.
    ///
    /// - Returns: The shared secret, and `getSetupURI(appName:accountName:)` for an authenticator app.
    /// - Throws: `AuthClientError.notSignedIn` for a signed-out, guest or federated session, and while a
    ///   sign-in waits on a challenge; `.configuration` without a user pool; `.sessionExpired`;
    ///   `.storageUnavailable`; `.notAuthorized` when Cognito rejects the access token (revoked, for
    ///   example); `.service` as Cognito answers otherwise.
    func setUpTOTP() async throws -> AuthClientTOTPSetupDetails {
        let core = core
        return try await core.signedInOperation("set up TOTP") { engine, payload in
            try await engine.setUpTOTP(payload)
        }
    }

    /// Completes a TOTP setup with a code from the authenticator app.
    ///
    /// - Throws: as `setUpTOTP()`; `.service(.softwareTokenMFANotEnabled, …)` for a wrong code, as
    ///   Cognito answers one (`EnableSoftwareTokenMFAException`). The setup can then be verified again
    ///   with a right code.
    func verifyTOTPSetup(
        code: String,
        options: AuthClientVerifyTOTPSetupOptions = AuthClientVerifyTOTPSetupOptions()
    ) async throws {
        let friendlyDeviceName = options.friendlyDeviceName
        let core = core
        try await core.signedInOperation("verify a TOTP setup") { engine, payload in
            try await engine.verifyTOTPSetup(payload, code: code, friendlyDeviceName: friendlyDeviceName)
        }
    }

    /// The signed-in user's MFA settings.
    ///
    /// - Throws: as `setUpTOTP()`.
    func fetchMFAPreference() async throws -> AuthClientUserMFAPreference {
        let core = core
        return try await core.signedInOperation("fetch the MFA preference") { engine, payload in
            try await engine.fetchMFAPreference(payload)
        }
    }

    /// Changes the signed-in user's MFA settings. A `nil` type is left as it is; `.enabled` keeps a type
    /// preferred if it already is.
    ///
    /// - Throws: as `setUpTOTP()`; `.service(.invalidParameter, …)` when more than one type would be
    ///   preferred.
    func updateMFAPreference(
        sms: AuthClientMFAPreference? = nil,
        totp: AuthClientMFAPreference? = nil,
        email: AuthClientMFAPreference? = nil
    ) async throws {
        let core = core
        try await core.signedInOperation("update the MFA preference") { engine, payload in
            try await engine.updateMFAPreference(payload, sms: sms, totp: totp, email: email)
        }
    }
}
