//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockAuthCategoryPlugin {

    public func confirmSignIn(
        challengeResponse: String,
        options: AuthConfirmSignInOperation.Request.Options? = nil,
        listener: AuthConfirmSignInOperation.ResultListener?
    ) -> AuthConfirmSignInOperation {
        notify()
        if let responder = responders.confirmSignIn {
            let result = responder(challengeResponse, options)
            listener?(result)
        }
        let request = AuthConfirmSignInOperation.Request(
            challengeResponse: challengeResponse,
            options: options ?? AuthConfirmSignInOperation.Request.Options()
        )
        return MockAuthConfirmSignInOperation(request: request)
    }

    public func confirmResetPassword(
        for username: String,
        with newPassword: String,
        confirmationCode: String,
        options: AuthConfirmResetPasswordOperation.Request.Options? = nil,
        listener: AuthConfirmResetPasswordOperation.ResultListener?
    ) -> AuthConfirmResetPasswordOperation {
        notify()
        if let responder = responders.confirmResetPassword {
            let result = responder(username, newPassword, confirmationCode, options)
            listener?(result)
        }
        let request = AuthConfirmResetPasswordOperation.Request(
            username: username,
            newPassword: newPassword,
            confirmationCode: confirmationCode,
            options: options ?? AuthConfirmResetPasswordOperation.Request.Options()
        )
        return MockAuthConfirmResetPasswordOperation(request: request)
    }

    public func confirmSignUp(
        for username: String,
        confirmationCode: String,
        options: AuthConfirmSignUpOperation.Request.Options? = nil,
        listener: AuthConfirmSignUpOperation.ResultListener?
    ) -> AuthConfirmSignUpOperation {
        notify()
        if let responder = responders.confirmSignUp {
            let result = responder(username, confirmationCode, options)
            listener?(result)
        }
        let request = AuthConfirmSignUpOperation.Request(
            username: username,
            code: confirmationCode,
            options: options ?? AuthConfirmSignUpOperation.Request.Options()
        )
        return MockAuthConfirmSignUpOperation(request: request)
    }

    public func fetchAuthSession(
        options: AuthFetchSessionOperation.Request.Options? = nil,
        listener: AuthFetchSessionOperation.ResultListener?
    ) -> AuthFetchSessionOperation {
        notify()
        if let responder = responders.fetchAuthSession {
            let result = responder(options)
            listener?(result)
        }
        let request = AuthFetchSessionOperation.Request(
            options: options ?? AuthFetchSessionOperation.Request.Options()
        )
        return MockAuthFetchSessionOperation(request: request)
    }

    public func resendSignUpCode(
        for username: String,
        options: AuthResendSignUpCodeOperation.Request.Options? = nil,
        listener: AuthResendSignUpCodeOperation.ResultListener?
    ) -> AuthResendSignUpCodeOperation {
        notify()
        if let responder = responders.resendSignUpCode {
            let result = responder(username, options)
            listener?(result)
        }
        let request = AuthResendSignUpCodeOperation.Request(
            username: username,
            options: options ?? AuthResendSignUpCodeOperation.Request.Options()
        )
        return MockAuthResendSignUpCodeOperation(request: request)
    }

    public func resetPassword(
        for username: String,
        options: AuthResetPasswordOperation.Request.Options? = nil,
        listener: AuthResetPasswordOperation.ResultListener?
    ) -> AuthResetPasswordOperation {
        notify()
        if let responder = responders.resetPassword {
            let result = responder(username, options)
            listener?(result)
        }
        let request = AuthResetPasswordOperation.Request(
            username: username,
            options: options ?? AuthResetPasswordOperation.Request.Options()
        )
        return MockAuthResetPasswordOperation(request: request)
    }

    public func signIn(
        username: String? = nil,
        password: String? = nil,
        options: AuthSignInOperation.Request.Options? = nil,
        listener: AuthSignInOperation.ResultListener?
    ) -> AuthSignInOperation {
        notify()
        if let responder = responders.signIn {
            let result = responder(username, password, options)
            listener?(result)
        }
        let request = AuthSignInOperation.Request(
            username: username,
            password: password,
            options: options ?? AuthSignInOperation.Request.Options()
        )
        return MockAuthSignInOperation(request: request)
    }

    public func signInWithWebUI(
        presentationAnchor: AuthUIPresentationAnchor,
        options: AuthWebUISignInOperation.Request.Options? = nil,
        listener: AuthWebUISignInOperation.ResultListener?
    ) -> AuthWebUISignInOperation {
        notify()
        if let responder = responders.signInWithWebUI {
            let result = responder(presentationAnchor, options)
            listener?(result)
        }
        let request = AuthWebUISignInOperation.Request(
            presentationAnchor: presentationAnchor,
            options: options ?? AuthWebUISignInOperation.Request.Options()
        )
        return MockAuthWebUISignInOperation(request: request)
    }

    public func signInWithWebUI(
        for authProvider: AuthProvider,
        presentationAnchor: AuthUIPresentationAnchor,
        options: AuthSocialWebUISignInOperation.Request.Options? = nil,
        listener: AuthSocialWebUISignInOperation.ResultListener?
    ) -> AuthSocialWebUISignInOperation {
        notify()
        if let responder = responders.signInWithWebUIForAuthProvider {
            let result = responder(authProvider, presentationAnchor, options)
            listener?(result)
        }
        let request = AuthSocialWebUISignInOperation.Request(
            presentationAnchor: presentationAnchor,
            authProvider: authProvider,
            options: options ?? AuthSocialWebUISignInOperation.Request.Options()
        )
        return MockAuthSocialWebUISignInOperation(request: request)
    }

    public func signOut(
        options: AuthSignOutOperation.Request.Options? = nil,
        listener: AuthSignOutOperation.ResultListener?
    ) -> AuthSignOutOperation {
        notify()
        if let responder = responders.signOut {
            let result = responder(options)
            listener?(result)
        }
        let request = AuthSignOutOperation.Request(
            options: options ?? AuthSignOutOperation.Request.Options()
        )
        return MockAuthSignOutOperation(request: request)
    }

    public func signUp(
        username: String,
        password: String? = nil,
        options: AuthSignUpOperation.Request.Options? = nil,
        listener: AuthSignUpOperation.ResultListener?
    ) -> AuthSignUpOperation {
        notify()
        if let responder = responders.signUp {
            let result = responder(username, password, options)
            listener?(result)
        }
        let request = AuthSignUpOperation.Request(
            username: username,
            password: password,
            options: options ?? AuthSignUpOperation.Request.Options()
        )
        return MockAuthSignUpOperation(request: request)
    }

}
