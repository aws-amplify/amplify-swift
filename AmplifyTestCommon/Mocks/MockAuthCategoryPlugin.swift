//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class MockAuthCategoryPlugin: MessageReporter, AuthCategoryPlugin {

    func signIn(username: String,
                password: String,
                options: AuthSignInOperation.Request.Options?,
                listener: AuthSignInOperation.EventListener?) -> AuthSignInOperation {
        fatalError()
    }

    public func signUp(username: String,
                       password: String? = nil,
                       options: AuthSignUpOperation.Request.Options? = nil,
                       listener: AuthSignUpOperation.EventListener?) -> AuthSignUpOperation {
        fatalError()
    }

    public func confirmSignUp(username: String,
                              confirmationCode: String,
                              options: AuthConfirmSignUpOperation.Request.Options? = nil,
                              listener: AuthConfirmSignUpOperation.EventListener?) -> AuthConfirmSignUpOperation {
        fatalError()
    }

    public func resendSignUpCode(username: String,
                                 options: AuthResendSignUpCodeOperation.Request.Options? = nil,
                                 listener: AuthResendSignUpCodeOperation.EventListener?)
        -> AuthResendSignUpCodeOperation {
            fatalError()
    }

    public func signIn(username: String? = nil,
                       password: String? = nil,
                       options: AuthSignInOperation.Request.Options? = nil,
                       listener: AuthSignInOperation.EventListener?) -> AuthSignInOperation {
        fatalError()
    }

    public func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthWebUISignInOperation.Request.Options? = nil,
                                listener: AuthWebUISignInOperation.EventListener?) -> AuthWebUISignInOperation {
        fatalError()
    }

    public func signInWithWebUI(for authProvider: AuthNProvider,
                                presentationAnchor: AuthUIPresentationAnchor,
                                options: AuthSocialWebUISignInOperation.Request.Options? = nil,
                                listener: AuthSocialWebUISignInOperation.EventListener?)
        -> AuthSocialWebUISignInOperation {
            fatalError()
    }

    public func confirmSignIn(challengeResponse: String,
                              options: AuthConfirmSignInOperation.Request.Options? = nil,
                              listener: AuthConfirmSignInOperation.EventListener?) -> AuthConfirmSignInOperation {
        fatalError()
    }

    public func signOut(options: AuthSignOutOperation.Request.Options? = nil,
                        listener: AuthSignOutOperation.EventListener?) -> AuthSignOutOperation {
        fatalError()
    }

    public func fetchAuthSession(options: AuthFetchSessionOperation.Request.Options? = nil,
                                 listener: AuthFetchSessionOperation.EventListener?) -> AuthFetchSessionOperation {
        fatalError()
    }

    public func resetPassword(for username: String,
                              options: AuthResetPasswordOperation.Request.Options? = nil,
                              listener: AuthResetPasswordOperation.EventListener?) -> AuthResetPasswordOperation {
        fatalError()
    }

    public func confirmResetPassword(for username: String,
                                     with newPassword: String,
                                     confirmationCode: String,
                                     options: AuthConfirmResetPasswordOperation.Request.Options? = nil,
                                     listener: AuthConfirmResetPasswordOperation.EventListener?)
        -> AuthConfirmResetPasswordOperation {
            fatalError()
    }

    public func getCurrentUser() -> AuthUser? {
        fatalError()
    }

    public func fetchUserAttributes(options: AuthFetchUserAttributeOperation.Request.Options? = nil,
                                listener: AuthFetchUserAttributeOperation.EventListener?)
        -> AuthFetchUserAttributeOperation {
            fatalError()
    }

    public func update(userAttribute: AuthUserAttribute,
                       options: AuthUpdateUserAttributeOperation.Request.Options? = nil,
                       listener: AuthUpdateUserAttributeOperation.EventListener?) -> AuthUpdateUserAttributeOperation {
        fatalError()
    }

    public func update(userAttributes: [AuthUserAttribute],
                       options: AuthUpdateUserAttributesOperation.Request.Options? = nil,
                       listener: AuthUpdateUserAttributesOperation.EventListener?)
        -> AuthUpdateUserAttributesOperation {
            fatalError()
    }

    public func resendConfirmationCode(for attributeKey: AuthUserAttributeKey,
                                       options: AuthAttributeResendConfirmationCodeOperation.Request.Options? = nil,
                                       listener: AuthAttributeResendConfirmationCodeOperation.EventListener?)
        -> AuthAttributeResendConfirmationCodeOperation {
            fatalError()

    }

    public func confirm(userAttribute: AuthUserAttributeKey,
                        confirmationCode: String,
                        options: AuthConfirmUserAttributeOperation.Request.Options? = nil,
                        listener: AuthConfirmUserAttributeOperation.EventListener?)
        -> AuthConfirmUserAttributeOperation {
            fatalError()
    }

    public func update(oldPassword: String,
                       to newPassword: String,
                       options: AuthChangePasswordOperation.Request.Options? = nil,
                       listener: AuthChangePasswordOperation.EventListener?) -> AuthChangePasswordOperation {
        notify("changePassword")
        let options = options ?? AuthChangePasswordRequest.Options()
        let request = AuthChangePasswordRequest(oldPassword: oldPassword,
                                                newPassword: newPassword,
                                                options: options)
        return MockAuthChangePasswordOperation(request: request)
    }

    public func fetchDevices(
        options: AuthFetchDevicesOperation.Request.Options? = nil,
        listener: AuthFetchDevicesOperation.EventListener?) -> AuthFetchDevicesOperation {
        fatalError()
    }

    public func forget(
        device: AuthDevice? = nil,
        options: AuthForgetDeviceOperation.Request.Options? = nil,
        listener: AuthForgetDeviceOperation.EventListener?) -> AuthForgetDeviceOperation {
        fatalError()
    }

    public func rememberDevice(
        options: AuthRememberDeviceOperation.Request.Options? = nil,
        listener: AuthRememberDeviceOperation.EventListener?) -> AuthRememberDeviceOperation {
        fatalError()
    }

    var key: String {
        return "MockAuthCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
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

class MockAuthChangePasswordOperation: AmplifyOperation<AuthChangePasswordRequest, Void, Void, AuthError>,
AuthChangePasswordOperation {

    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.changePassword,
                   request: request)
    }

}
