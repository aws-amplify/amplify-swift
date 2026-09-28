//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth

/// TOTP setup and MFA preferences, ported from the plugin's `SetUpTOTPTask`,
/// `VerifyTOTPSetupTask`, `FetchMFAPreferenceTask` and `UpdateMFAPreferenceTask`.
///
/// Each is one or two direct Cognito calls with the payload's access token, as the plugin's tasks call the
/// user pool with the session's token: no state machine, no refresh (the core hands over the payload as it
/// is), and nothing written. They are `nonisolated` and touch none of the actor's state, so they never wait
/// for, or disturb, a pending sign-in. The plugin validates none of their arguments, so neither does the
/// client: Cognito answers an empty or malformed code.
///
/// **Errors.** A Cognito exception is mapped as the plugin maps it (`EngineAuthErrorConvertible`), so a
/// wrong code in `verifyTOTPSetup` is `.service(.softwareTokenMFANotEnabled, …)` and two preferred types in
/// `updateMFAPreference` are `.service(.invalidParameter, …)`. The plugin's own errors keep its strings.
/// Anything else is left to the core, which maps it with `operationFailure`.
extension LiveSessionEngine {

    /// Associates a new TOTP secret with the payload's user (`SetUpTOTPTask.setUpTOTP`).
    ///
    /// - Returns: The secret and the payload's username, for `getSetupURI(appName:accountName:)`.
    /// - Throws: `SessionEngineError.notSignedIn` without a user; `.service` as Cognito answers, or with the
    ///   plugin's "Secret code cannot be retrieved" when it returns none.
    nonisolated func setUpTOTP(_ payload: Data) async throws -> AuthClientTOTPSetupDetails {
        let call = try mfaCall(payload)
        let output = try await Self.mappingMFAErrors {
            try await call.userPool.associateSoftwareToken(input: AssociateSoftwareTokenInput(accessToken: call.accessToken))
        }
        guard let secretCode = output.secretCode else {
            throw AuthClientError.service(nil, "Secret code cannot be retrieved", "")
        }
        return AuthClientTOTPSetupDetails(sharedSecret: secretCode, username: call.username)
    }

    /// Verifies a code from the authenticator app, which completes the TOTP setup
    /// (`VerifyTOTPSetupTask.verifyTOTPSetup`). `friendlyDeviceName` is sent as given.
    ///
    /// - Throws: `SessionEngineError.notSignedIn` without a user; `.service` as Cognito answers
    ///   (`softwareTokenMFANotEnabled` for a wrong code), or with the plugin's strings when the status is
    ///   missing or not `SUCCESS`.
    nonisolated func verifyTOTPSetup(_ payload: Data, code: String, friendlyDeviceName: String?) async throws {
        let call = try mfaCall(payload)
        let output = try await Self.mappingMFAErrors {
            try await call.userPool.verifySoftwareToken(input: VerifySoftwareTokenInput(
                accessToken: call.accessToken,
                friendlyDeviceName: friendlyDeviceName,
                userCode: code
            ))
        }
        guard let status = output.status else {
            throw AuthClientError.service(
                nil,
                "Verify TOTP Result cannot be retrieved",
                EngineErrorMessages.shouldNotHappenReportBugToAWS()
            )
        }
        switch status {
        case .success:
            return
        case .error:
            throw AuthClientError.service(nil, "Unknown service error occurred", EngineErrorMessages.reportBugToAWS())
        case .sdkUnknown(let value):
            throw AuthClientError.service(nil, value, EngineErrorMessages.reportBugToAWS())
        }
    }

    /// The user's MFA settings from `GetUser` (`FetchMFAPreferenceTask.fetchMFAPreference`): `enabled` is
    /// `nil` when no type is on, and names Cognito does not map to a type are skipped.
    ///
    /// - Throws: `SessionEngineError.notSignedIn` without a user; `.service` as Cognito answers.
    nonisolated func fetchMFAPreference(_ payload: Data) async throws -> AuthClientUserMFAPreference {
        let call = try mfaCall(payload)
        let output = try await Self.mappingMFAErrors {
            try await call.userPool.getUser(input: GetUserInput(accessToken: call.accessToken))
        }
        return Self.preference(settingList: output.userMFASettingList, preferred: output.preferredMfaSetting)
    }

    /// Sets the user's MFA settings (`UpdateMFAPreferenceTask.updateMFAPreference`): reads the preferred
    /// type with `GetUser` first, so `.enabled` keeps a type preferred if it already is, then sends one
    /// `SetUserMFAPreference` with a setting for each non-`nil` argument only.
    ///
    /// - Throws: `SessionEngineError.notSignedIn` without a user; `.service` as Cognito answers
    ///   (`invalidParameter` when two types are preferred).
    nonisolated func updateMFAPreference(
        _ payload: Data,
        sms: AuthClientMFAPreference?,
        totp: AuthClientMFAPreference?,
        email: AuthClientMFAPreference?
    ) async throws {
        let call = try mfaCall(payload)
        let current = try await Self.mappingMFAErrors {
            try await call.userPool.getUser(input: GetUserInput(accessToken: call.accessToken))
        }
        let preferred = current.preferredMfaSetting.flatMap(EngineMFAType.init(rawValue:))
        let input = SetUserMFAPreferenceInput(
            accessToken: call.accessToken,
            emailMfaSettings: email.map { .init($0.mfaSetting(isCurrentlyPreferred: preferred == .email)) },
            smsMfaSettings: sms.map { .init($0.mfaSetting(isCurrentlyPreferred: preferred == .sms)) },
            softwareTokenMfaSettings: totp.map { .init($0.mfaSetting(isCurrentlyPreferred: preferred == .totp)) }
        )
        _ = try await Self.mappingMFAErrors {
            try await call.userPool.setUserMFAPreference(input: input)
        }
    }

    // MARK: Helpers

    /// What each MFA call needs: the user pool, and the payload's access token and username, used as they
    /// are.
    private struct MFACall: Sendable {
        let userPool: any CognitoUserPoolBehavior
        let accessToken: String
        let username: String
    }

    /// - Throws: `configuration` without a user pool; `SessionEngineError.notSignedIn` when the payload has
    ///   no user pool user (the core has already refused such a session).
    private nonisolated func mfaCall(_ payload: Data) throws -> MFACall {
        try requireUserPool()
        let signedIn: SignedInData
        switch try Self.credentials(in: payload) {
        case .userPoolOnly(let data), .userPoolAndIdentityPool(let data, _, _):
            signedIn = data
        case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
            throw SessionEngineError.notSignedIn
        }
        return try MFACall(
            userPool: EngineResources.required(resources.services.userPool, "user pool"),
            accessToken: signedIn.cognitoUserPoolTokens.accessToken,
            username: signedIn.username
        )
    }

    /// Runs one Cognito call, mapping its exception as the plugin's `AuthError(converting:)` does.
    private static func mappingMFAErrors<T>(_ body: () async throws -> T) async throws -> T {
        do {
            return try await body()
        } catch let error as EngineAuthErrorConvertible {
            throw AuthClientError(engine: error.engineError)
        }
    }

    /// `GetUser`'s MFA fields as the plugin reads them.
    static func preference(settingList: [String]?, preferred: String?) -> AuthClientUserMFAPreference {
        var enabled: Set<AuthClientMFAType>?
        for name in settingList ?? [] {
            guard let type = EngineMFAType(rawValue: name) else {
                continue
            }
            enabled = (enabled ?? []).union([AuthClientMFAType(type)])
        }
        return AuthClientUserMFAPreference(
            enabled: enabled,
            preferred: preferred.flatMap(EngineMFAType.init(rawValue:)).map(AuthClientMFAType.init)
        )
    }
}

/// One MFA type's setting, as the plugin's `MFAPreference` extension builds it.
private struct MFASetting: Equatable {
    let enabled: Bool
    let preferredMfa: Bool
}

private extension AuthClientMFAPreference {

    /// `.enabled` keeps the type preferred if it `isCurrentlyPreferred`; `.preferred` and `.notPreferred`
    /// set it; `.disabled` turns the type off, with the SDK's default `preferredMfa` (`false`), as the
    /// plugin's `.init(enabled: false)`.
    func mfaSetting(isCurrentlyPreferred: Bool) -> MFASetting {
        switch self {
        case .enabled:
            return MFASetting(enabled: true, preferredMfa: isCurrentlyPreferred)
        case .preferred:
            return MFASetting(enabled: true, preferredMfa: true)
        case .notPreferred:
            return MFASetting(enabled: true, preferredMfa: false)
        case .disabled:
            return MFASetting(enabled: false, preferredMfa: false)
        }
    }
}

private extension CognitoIdentityProviderClientTypes.SMSMfaSettingsType {
    init(_ setting: MFASetting) {
        self.init(enabled: setting.enabled, preferredMfa: setting.preferredMfa)
    }
}

private extension CognitoIdentityProviderClientTypes.SoftwareTokenMfaSettingsType {
    init(_ setting: MFASetting) {
        self.init(enabled: setting.enabled, preferredMfa: setting.preferredMfa)
    }
}

private extension CognitoIdentityProviderClientTypes.EmailMfaSettingsType {
    init(_ setting: MFASetting) {
        self.init(enabled: setting.enabled, preferredMfa: setting.preferredMfa)
    }
}
