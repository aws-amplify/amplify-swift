//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

class MockAuthCategoryPlugin: MessageReporter, AuthCategoryPlugin {

    func getCurrentUser() async throws -> any AuthUser {
        fatalError()
    }

    func signIn(
        username: String,
        password: String,
        options: AuthSignInRequest.Options?
    ) async throws -> AuthSignInResult {
        fatalError()
    }

    func signUp(username: String, password: String? = nil, options: AuthSignUpRequest.Options? = nil) async throws -> AuthSignUpResult {
        fatalError()
    }

    func confirmSignUp(
        for username: String,
        confirmationCode: String,
        options: AuthConfirmSignUpRequest.Options? = nil
    ) async throws -> AuthSignUpResult {
        fatalError()
    }

    func resendSignUpCode(for username: String, options: AuthResendSignUpCodeRequest.Options? = nil) async throws -> AuthCodeDeliveryDetails {
            fatalError()
    }

    func signIn(
        username: String? = nil,
        password: String? = nil,
        options: AuthSignInRequest.Options? = nil
    ) async throws -> AuthSignInResult {
        fatalError()
    }

#if os(iOS) || os(macOS) || os(visionOS)
    func signInWithWebUI(
        presentationAnchor: AuthUIPresentationAnchor? = nil,
        options: AuthWebUISignInRequest.Options? = nil
    ) async throws -> AuthSignInResult {
        fatalError()
    }

    func signInWithWebUI(
        for authProvider: AuthProvider,
        presentationAnchor: AuthUIPresentationAnchor? = nil,
        options: AuthWebUISignInRequest.Options? = nil
    ) async throws -> AuthSignInResult {
        fatalError()
    }
#endif

    func confirmSignIn(
        challengeResponse: String,
        options: AuthConfirmSignInRequest.Options? = nil
    ) async throws -> AuthSignInResult {
        fatalError()
    }

    func signOut(options: AuthSignOutRequest.Options? = nil) async -> AuthSignOutResult {
        fatalError()
    }

    func autoSignIn() async throws -> AuthSignInResult {
        fatalError()
    }

    func deleteUser() async throws {
        fatalError()
    }

    func fetchAuthSession(options: AuthFetchSessionRequest.Options? = nil) async throws -> AuthSession {
        fatalError()
    }

    func resetPassword(for username: String, options: AuthResetPasswordRequest.Options? = nil) async throws -> AuthResetPasswordResult {
        fatalError()
    }

    func confirmResetPassword(
        for username: String,
        with newPassword: String,
        confirmationCode: String,
        options: AuthConfirmResetPasswordRequest.Options? = nil
    ) async throws {
            fatalError()
    }

    func fetchUserAttributes(options: AuthFetchUserAttributesRequest.Options? = nil) async throws -> [AuthUserAttribute] {
            fatalError()
    }

    func update(userAttribute: AuthUserAttribute, options: AuthUpdateUserAttributeRequest.Options? = nil) async throws -> AuthUpdateAttributeResult {
        fatalError()
    }

    func update(userAttributes: [AuthUserAttribute], options: AuthUpdateUserAttributesRequest.Options? = nil) async throws -> [AuthUserAttributeKey: AuthUpdateAttributeResult] {
            fatalError()
    }

    func resendConfirmationCode(forUserAttributeKey userAttributeKey: AuthUserAttributeKey, options: AuthAttributeResendConfirmationCodeRequest.Options? = nil)
        async throws -> AuthCodeDeliveryDetails {
            fatalError()
    }

    func sendVerificationCode(
        forUserAttributeKey userAttributeKey: AuthUserAttributeKey,
        options: AuthSendUserAttributeVerificationCodeRequest.Options? = nil
    )
    async throws -> AuthCodeDeliveryDetails {
        fatalError()
    }

    func setUpTOTP() async throws -> TOTPSetupDetails {
        fatalError()
    }

    func verifyTOTPSetup(
        code: String,
        options: VerifyTOTPSetupRequest.Options?
    ) async throws {
        fatalError()
    }

    func confirm(
        userAttribute: AuthUserAttributeKey,
        confirmationCode: String,
        options: AuthConfirmUserAttributeRequest.Options? = nil
    ) async throws {
            fatalError()
    }

    func update(
        oldPassword: String,
        to newPassword: String,
        options: AuthChangePasswordRequest.Options? = nil
    ) async throws {
        notify("changePassword")

    }

    func fetchDevices(options: AuthFetchDevicesRequest.Options? = nil) -> [AuthDevice] {
        fatalError()
    }

    func forgetDevice(_ device: AuthDevice? = nil, options: AuthForgetDeviceRequest.Options? = nil) async throws {
        fatalError()
    }

    func rememberDevice( options: AuthRememberDeviceRequest.Options? = nil) async throws {
        fatalError()
    }

#if os(iOS) || os(macOS)
    func associateWebAuthnCredential(presentationAnchor: AuthUIPresentationAnchor?, options: AuthAssociateWebAuthnCredentialRequest.Options?) async throws {
        fatalError()
    }
#elseif os(visionOS)
    func associateWebAuthnCredential(presentationAnchor: AuthUIPresentationAnchor, options: AuthAssociateWebAuthnCredentialRequest.Options?) async throws {
        fatalError()
    }
#endif

    func listWebAuthnCredentials(options: AuthListWebAuthnCredentialsRequest.Options?) async throws -> AuthListWebAuthnCredentialsResult {
        fatalError()
    }

    func deleteWebAuthnCredential(credentialId: String, options: AuthDeleteWebAuthnCredentialRequest.Options?) async throws {
        fatalError()
    }

    var key: String {
        return "MockAuthCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset() {
        notify("reset")
    }
}

class MockSecondAuthCategoryPlugin: MockAuthCategoryPlugin {
    override var key: String {
        return "MockSecondAuthCategoryPlugin"
    }
}

class MockAuthCategoryPluginWithoutKey: MockAuthCategoryPlugin {
    override var key: String {
        return ""
    }
}
