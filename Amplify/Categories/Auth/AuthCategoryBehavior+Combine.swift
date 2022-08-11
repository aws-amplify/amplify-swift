//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

// No-listener versions of the public APIs, to clean call sites that use Combine
// publishers to get results

public extension AuthCategoryBehavior {

    /// SignUp a user with the authentication provider.
    ///
    /// If the signUp require multiple steps like passing a confirmation code, use the method
    /// `confirmSignUp` after this api completes. You can check if the user is confirmed or not
    /// using the result `AuthSignUpResult.userConfirmed`.
    ///
    /// - Parameters:
    ///   - username: username to signUp
    ///   - password: password as per the password policy of the provider
    ///   - options: Parameters specific to plugin behavior
    func signUp(
        username: String,
        password: String? = nil,
        options: AuthSignUpOperation.Request.Options? = nil
    ) -> AuthSignUpOperation {
        signUp(username: username, password: password, options: options, listener: nil)
    }

    /// Confirms the `signUp` operation.
    ///
    /// Invoke this operation as a follow up for the signUp process if the authentication provider
    /// that you are using required to follow a next step after signUp. Calling this operation without
    /// first calling `signUp` or `resendSignUpCode` may cause an error.
    /// - Parameters:
    ///   - username: Username used that was used to signUp.
    ///   - confirmationCode: Confirmation code received to the user.
    ///   - options: Parameters specific to plugin behavior
    func confirmSignUp(
        for username: String,
        confirmationCode: String,
        options: AuthConfirmSignUpOperation.Request.Options? = nil
    ) -> AuthConfirmSignUpOperation {
        confirmSignUp(
            for: username,
            confirmationCode: confirmationCode,
            options: options,
            listener: nil
        )
    }

    /// Resends the confirmation code to confirm the signUp process
    ///
    /// - Parameters:
    ///   - username: Username of the user to be confirmed.
    ///   - options: Parameters specific to plugin behavior.
    func resendSignUpCode(
        for username: String,
        options: AuthResendSignUpCodeOperation.Request.Options? = nil
    ) -> AuthResendSignUpCodeOperation {
        resendSignUpCode(for: username, options: options, listener: nil)
    }

    /// SignIn to the authentication provider
    ///
    /// Username and password are optional values, check the plugin documentation to decide on what all values need to
    /// passed. For example in a passwordless flow you just need to pass the username and the passwordcould be nil.
    ///
    /// - Parameters:
    ///   - username: Username to signIn the user
    ///   - password: Password to signIn the user
    ///   - options: Parameters specific to plugin behavior
    func signIn(
        username: String? = nil,
        password: String? = nil,
        migrationEnabled: Bool = false,
        options: AuthSignInOperation.Request.Options? = nil
    ) -> AuthSignInOperation {
        signIn(username: username, password: password, migrationEnabled: migrationEnabled, options: options, listener: nil)
    }

    /// SignIn using pre configured web UI.
    ///
    /// Calling this method will always launch the Auth plugin's default web user interface
    ///
    /// - Parameters:
    ///   - presentationAnchor: Anchor on which the UI is presented.
    ///   - options: Parameters specific to plugin behavior.
    func signInWithWebUI(
        presentationAnchor: AuthUIPresentationAnchor,
        options: AuthWebUISignInOperation.Request.Options? = nil
    ) -> AuthWebUISignInOperation {
        signInWithWebUI(presentationAnchor: presentationAnchor, options: options, listener: nil)
    }

    /// SignIn using an auth provider on a web UI
    ///
    /// Calling this method will invoke the AuthProvider's default web user interface. Depending on the plugin
    /// implementation and the authentication state with the provider, this method might complete without showing
    /// any UI.
    ///
    /// - Parameters:
    ///   - authProvider: Auth provider used to signIn.
    ///   - presentationAnchor: Anchor on which the UI is presented.
    ///   - options: Parameters specific to plugin behavior.
    func signInWithWebUI(
        for authProvider: AuthProvider,
        presentationAnchor: AuthUIPresentationAnchor,
        options: AuthSocialWebUISignInOperation.Request.Options? = nil
    ) -> AuthSocialWebUISignInOperation {
        signInWithWebUI(
            for: authProvider,
            presentationAnchor: presentationAnchor,
            options: options,
            listener: nil
        )
    }

    /// Confirms a next step in signIn flow.
    ///
    /// - Parameters:
    ///   - challengeResponse: Challenge response required to confirm the next step in signIn flow
    ///   - options: Parameters specific to plugin behavior.
    func confirmSignIn(
        challengeResponse: String,
        options: AuthConfirmSignInOperation.Request.Options? = nil
    ) -> AuthConfirmSignInOperation {
        confirmSignIn(challengeResponse: challengeResponse, options: options, listener: nil)
    }

    func signOut(
        options: AuthSignOutOperation.Request.Options? = nil
    ) -> AuthSignOutOperation {
        signOut(options: options, listener: nil)
    }

    /// Delete the account of the currently logged-in user.
    ///
    /// - Returns: AuthDeleteUserOperation
    @discardableResult
    func deleteUser() -> AuthDeleteUserOperation {
        deleteUser(listener: nil)
    }

    /// Fetch the current authentication session.
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior
    func fetchAuthSession(
        options: AuthFetchSessionOperation.Request.Options? = nil
    ) -> AuthFetchSessionOperation {
        fetchAuthSession(options: options, listener: nil)
    }

    /// Initiate a reset password flow for the user
    ///
    /// - Parameters:
    ///   - username: username whose password need to reset
    ///   - options: Parameters specific to plugin behavior
    func resetPassword(
        for username: String,
        options: AuthResetPasswordOperation.Request.Options? = nil
    ) -> AuthResetPasswordOperation {
        resetPassword(for: username, options: options, listener: nil)
    }

    /// Confirms a reset password flow
    ///
    /// - Parameters:
    ///   - username: username whose password need to reset
    ///   - newPassword: new password for the user
    ///   - confirmationCode: Received confirmation code
    ///   - options: Parameters specific to plugin behavior
    func confirmResetPassword(
        for username: String,
        with newPassword: String,
        confirmationCode: String,
        options: AuthConfirmResetPasswordOperation.Request.Options? = nil
    ) -> AuthConfirmResetPasswordOperation {
        confirmResetPassword(
            for: username,
            with: newPassword,
            confirmationCode: confirmationCode,
            options: options,
            listener: nil
        )
    }

}
