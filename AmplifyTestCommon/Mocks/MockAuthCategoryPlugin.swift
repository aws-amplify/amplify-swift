//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class MockAuthCategoryPlugin: MessageReporter, AuthCategoryPlugin {

    public func getCurrentUser() async throws -> AuthUser {
        fatalError()
    }

    func signIn(username: String,
                password: String,
                options: AuthSignInRequest.Options?) async throws -> AuthSignInResult {
        fatalError()
    }

    public func signUp(username: String, password: String? = nil, options: AuthSignUpRequest.Options? = nil) async throws -> AuthSignUpResult {
        fatalError()
    }

    public func confirmSignUp(for username: String,
                              confirmationCode: String,
                              options: AuthConfirmSignUpRequest.Options? = nil) async throws -> AuthSignUpResult {
        fatalError()
    }

    public func resendSignUpCode(for username: String, options: AuthResendSignUpCodeRequest.Options? = nil) async throws -> AuthCodeDeliveryDetails {
            fatalError()
    }

    public func signIn(username: String? = nil,
                       password: String? = nil,
                       options: AuthSignInRequest.Options? = nil) async throws -> AuthSignInResult {
        fatalError()
    }

#if os(watchOS)
    public func signInWithWebUI(options: AuthWebUISignInRequest.Options? = nil) async throws -> AuthSignInResult {
        fatalError()
    }

    public func signInWithWebUI(for authProvider: AuthProvider,
                                options: AuthWebUISignInRequest.Options? = nil) async throws -> AuthSignInResult {
        fatalError()
    }
#elseif !os(tvOS)
    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor? = nil,
                                options: AuthWebUISignInRequest.Options? = nil) async throws -> AuthSignInResult {
        fatalError()
    }

    public func signInWithWebUI(for authProvider: AuthProvider,
                                presentationAnchor: AuthUIPresentationAnchor? = nil,
                                options: AuthWebUISignInRequest.Options? = nil) async throws -> AuthSignInResult {
        fatalError()
    }
#endif

    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInRequest.Options? = nil) async throws -> AuthSignInResult {
        fatalError()
    }

    public func signOut(options: AuthSignOutRequest.Options? = nil) async -> AuthSignOutResult {
        fatalError()
    }

    public func deleteUser() async throws {
        fatalError()
    }

    public func fetchAuthSession(options: AuthFetchSessionRequest.Options? = nil) async throws -> AuthSession {
        fatalError()
    }

    public func resetPassword(for username: String, options: AuthResetPasswordRequest.Options? = nil) async throws -> AuthResetPasswordResult {
        fatalError()
    }

    public func confirmResetPassword(for username: String,
                                     with newPassword: String,
                                     confirmationCode: String,
                                     options: AuthConfirmResetPasswordRequest.Options? = nil) async throws {
            fatalError()
    }

    public func fetchUserAttributes(options: AuthFetchUserAttributesRequest.Options? = nil) async throws -> [AuthUserAttribute] {
            fatalError()
    }

    public func update(userAttribute: AuthUserAttribute, options: AuthUpdateUserAttributeRequest.Options? = nil) async throws -> AuthUpdateAttributeResult {
        fatalError()
    }

    public func update(userAttributes: [AuthUserAttribute], options: AuthUpdateUserAttributesRequest.Options? = nil) async throws -> [AuthUserAttributeKey: AuthUpdateAttributeResult] {
            fatalError()
    }

    public func resendConfirmationCode(forUserAttributeKey userAttributeKey: AuthUserAttributeKey, options: AuthAttributeResendConfirmationCodeRequest.Options? = nil)
        async throws -> AuthCodeDeliveryDetails {
            fatalError()

    }

    public func confirm(userAttribute: AuthUserAttributeKey,
                        confirmationCode: String,
                        options: AuthConfirmUserAttributeRequest.Options? = nil) async throws {
            fatalError()
    }

    public func update(oldPassword: String,
                       to newPassword: String,
                       options: AuthChangePasswordRequest.Options? = nil) async throws {
        notify("changePassword")

    }

    public func fetchDevices(options: AuthFetchDevicesRequest.Options? = nil) -> [AuthDevice] {
        fatalError()
    }

    public func forgetDevice(_ device: AuthDevice? = nil, options: AuthForgetDeviceRequest.Options? = nil) async throws {
        fatalError()
    }

    public func rememberDevice( options: AuthRememberDeviceRequest.Options? = nil) async throws {
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
