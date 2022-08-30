//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class MockAuthCategoryPlugin: MessageReporter, AuthCategoryPlugin {

    public func getCurrentUser() async -> AuthUser? {
        return nil
    }

    public func getCurrentUser(closure: @escaping (Result<AuthUser?, Error>) -> Void) {
        closure(.success(nil))
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

#if canImport(AuthenticationServices)
    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInRequest.Options? = nil) async throws -> AuthSignInResult {
        fatalError()
    }

    public func signInWithWebUI(for authProvider: AuthProvider,
                                presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInRequest.Options? = nil) async throws -> AuthSignInResult {
            fatalError()
    }
#endif

    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInRequest.Options? = nil) async throws -> AuthSignInResult {
        fatalError()
    }

    public func signOut(options: AuthSignOutRequest.Options? = nil) async throws {
        fatalError()
    }

    public func deleteUser() async throws {
        fatalError()
    }

    public func fetchAuthSession(options: AuthFetchSessionOperation.Request.Options? = nil,
                                 listener: AuthFetchSessionOperation.ResultListener?) -> AuthFetchSessionOperation {
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

    public func fetchUserAttributes(
        options: AuthFetchUserAttributeOperation.Request.Options? = nil,
        listener: AuthFetchUserAttributeOperation.ResultListener?
    ) -> AuthFetchUserAttributeOperation {
            fatalError()
    }

    public func update(userAttribute: AuthUserAttribute,
                       options: AuthUpdateUserAttributeOperation.Request.Options? = nil,
                       listener: AuthUpdateUserAttributeOperation.ResultListener?) -> AuthUpdateUserAttributeOperation {
        fatalError()
    }

    public func update(userAttributes: [AuthUserAttribute],
                       options: AuthUpdateUserAttributesOperation.Request.Options? = nil,
                       listener: AuthUpdateUserAttributesOperation.ResultListener?)
        -> AuthUpdateUserAttributesOperation {
            fatalError()
    }

    public func resendConfirmationCode(for attributeKey: AuthUserAttributeKey,
                                       options: AuthAttributeResendConfirmationCodeOperation.Request.Options? = nil,
                                       listener: AuthAttributeResendConfirmationCodeOperation.ResultListener?)
        -> AuthAttributeResendConfirmationCodeOperation {
            fatalError()

    }

    public func confirm(userAttribute: AuthUserAttributeKey,
                        confirmationCode: String,
                        options: AuthConfirmUserAttributeOperation.Request.Options? = nil,
                        listener: AuthConfirmUserAttributeOperation.ResultListener?)
        -> AuthConfirmUserAttributeOperation {
            fatalError()
    }

    public func update(oldPassword: String,
                       to newPassword: String,
                       options: AuthChangePasswordRequest.Options? = nil) async throws {
        notify("changePassword")

    }

    public func fetchDevices(
        options: AuthFetchDevicesOperation.Request.Options? = nil,
        listener: AuthFetchDevicesOperation.ResultListener?) -> AuthFetchDevicesOperation {
        fatalError()
    }

    public func forgetDevice(
        _ device: AuthDevice? = nil,
        options: AuthForgetDeviceOperation.Request.Options? = nil,
        listener: AuthForgetDeviceOperation.ResultListener?) -> AuthForgetDeviceOperation {
        fatalError()
    }

    public func rememberDevice(
        options: AuthRememberDeviceOperation.Request.Options? = nil,
        listener: AuthRememberDeviceOperation.ResultListener?) -> AuthRememberDeviceOperation {
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
