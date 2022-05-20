//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class MockAuthCategoryPlugin: MessageReporter, AuthCategoryPlugin {

    func signIn(username: String,
                password: String,
                options: AuthSignInOperation.Request.Options?,
                listener: AuthSignInOperation.ResultListener?) -> AuthSignInOperation {
        fatalError()
    }

    public func signUp(username: String,
                       password: String? = nil,
                       options: AuthSignUpOperation.Request.Options? = nil,
                       listener: AuthSignUpOperation.ResultListener?) -> AuthSignUpOperation {
        fatalError()
    }

    public func confirmSignUp(for username: String,
                              confirmationCode: String,
                              options: AuthConfirmSignUpOperation.Request.Options? = nil,
                              listener: AuthConfirmSignUpOperation.ResultListener?) -> AuthConfirmSignUpOperation {
        fatalError()
    }

    public func resendSignUpCode(for username: String,
                                 options: AuthResendSignUpCodeOperation.Request.Options? = nil,
                                 listener: AuthResendSignUpCodeOperation.ResultListener?)
        -> AuthResendSignUpCodeOperation {
            fatalError()
    }

    public func signIn(username: String? = nil,
                       password: String? = nil,
                       options: AuthSignInOperation.Request.Options? = nil,
                       listener: AuthSignInOperation.ResultListener?) -> AuthSignInOperation {
        fatalError()
    }

#if canImport(AuthenticationServices)
    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInOperation.Request.Options? = nil,
                                listener: AuthWebUISignInOperation.ResultListener?) -> AuthWebUISignInOperation {
        fatalError()
    }

    public func signInWithWebUI(for authProvider: AuthProvider,
                                presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthSocialWebUISignInOperation.Request.Options? = nil,
                                listener: AuthSocialWebUISignInOperation.ResultListener?)
        -> AuthSocialWebUISignInOperation {
            fatalError()
    }
#endif

    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInOperation.Request.Options? = nil,
                              listener: AuthConfirmSignInOperation.ResultListener?) -> AuthConfirmSignInOperation {
        fatalError()
    }

    public func signOut(options: AuthSignOutOperation.Request.Options? = nil,
                        listener: AuthSignOutOperation.ResultListener?) -> AuthSignOutOperation {
        fatalError()
    }

    public func deleteUser(listener: AuthDeleteUserOperation.ResultListener?) -> AuthDeleteUserOperation {
        fatalError()
    }

    public func fetchAuthSession(options: AuthFetchSessionOperation.Request.Options? = nil,
                                 listener: AuthFetchSessionOperation.ResultListener?) -> AuthFetchSessionOperation {
        fatalError()
    }

    public func resetPassword(for username: String,
                              options: AuthResetPasswordOperation.Request.Options? = nil,
                              listener: AuthResetPasswordOperation.ResultListener?) -> AuthResetPasswordOperation {
        fatalError()
    }

    public func confirmResetPassword(for username: String,
                                     with newPassword: String,
                                     confirmationCode: String,
                                     options: AuthConfirmResetPasswordOperation.Request.Options? = nil,
                                     listener: AuthConfirmResetPasswordOperation.ResultListener?)
        -> AuthConfirmResetPasswordOperation {
            fatalError()
    }

    public func getCurrentUser() -> AuthUser? {
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
                       options: AuthChangePasswordOperation.Request.Options? = nil,
                       listener: AuthChangePasswordOperation.ResultListener?) -> AuthChangePasswordOperation {
        notify("changePassword")
        let options = options ?? AuthChangePasswordRequest.Options()
        let request = AuthChangePasswordRequest(oldPassword: oldPassword,
                                                newPassword: newPassword,
                                                options: options)
        return MockAuthChangePasswordOperation(request: request)
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

    func reset(onComplete: @escaping BasicClosure) {
        notify("reset")
        onComplete()
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

class MockAuthChangePasswordOperation: AmplifyOperation<AuthChangePasswordRequest, Void, AuthError>,
AuthChangePasswordOperation {

    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.changePasswordAPI,
                   request: request)
    }

}
