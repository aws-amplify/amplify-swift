//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class MockAuthCategoryPlugin: MessageReporter, AuthCategoryPlugin {

    func signUp(username: String,
                password: String,
                options: AuthSignUpOperation.Request.Options?,
                listener: AuthSignUpOperation.EventListener?) -> AuthSignUpOperation {
        fatalError()
    }

    func confirmSignUp(username: String,
                       confirmationCode: String,
                       options: AuthConfirmSignUpOperation.Request.Options?,
                       listener: AuthConfirmSignUpOperation.EventListener?) -> AuthConfirmSignUpOperation {
        fatalError()
    }

    func signIn(username: String,
                password: String,
                options: AuthSignInOperation.Request.Options?,
                listener: AuthSignInOperation.EventListener?) -> AuthSignInOperation {
        fatalError()
    }

    func signInWithSocial(provider: AuthSocialProvider,
                          token: String,
                          options: AuthSocialSignInOperation.Request.Options?,
                          listener: AuthSocialSignInOperation.EventListener?) -> AuthSocialSignInOperation {
        fatalError()
    }

    func signInWithUI(options: AuthUISignInOperation.Request.Options?,
                      listener: AuthUISignInOperation.EventListener?) -> AuthUISignInOperation {
        fatalError()
    }

    func fetchAuthState(listener: AuthStateOperation.EventListener?) -> AuthStateOperation {
        fatalError()
    }

    // MARK: - Password Management

    func forgotPassword(username: String,
                        options: AuthForgotPasswordOperation.Request.Options?,
                        listener: AuthForgotPasswordOperation.EventListener?) -> AuthForgotPasswordOperation {
        fatalError()
    }

    func confirmForgotPassword(username: String,
                               newPassword: String,
                               confirmationCode: String,
                               options: AuthConfirmForgotPasswordOperation.Request.Options?,
                               listener: AuthConfirmForgotPasswordOperation.EventListener?) -> AuthConfirmForgotPasswordOperation {
        fatalError()
    }

    func changePassword(currentPassword: String,
                        newPassword: String,
                        options: AuthChangePasswordOperation.Request.Options? = nil,
                        listener: AuthChangePasswordOperation.EventListener? = nil) -> AuthChangePasswordOperation {
        notify("changePassword")
        let options = options ?? AuthChangePasswordRequest.Options()
        let request = AuthChangePasswordRequest(currentPassword: currentPassword,
                                                newPassword: newPassword,
                                                options: options)
        return MockAuthChangePasswordOperation(request: request)
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

class MockAuthChangePasswordOperation: AmplifyOperation<AuthChangePasswordRequest, Void, AuthChangePasswordResult, AmplifyAuthError>,
AuthChangePasswordOperation {

    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.changePassword,
                   request: request)
    }

}
