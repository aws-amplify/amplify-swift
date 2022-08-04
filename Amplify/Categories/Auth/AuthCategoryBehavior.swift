//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if canImport(AuthenticationServices)
import AuthenticationServices

public typealias AuthUIPresentationAnchor = ASPresentationAnchor
#endif

/// Behavior of the Auth category that clients will use
public protocol AuthCategoryBehavior: AuthCategoryUserBehavior, AuthCategoryDeviceBehavior {

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
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func signUp(username: String,
                password: String?,
                options: AuthSignUpOperation.Request.Options?,
                listener: AuthSignUpOperation.ResultListener?) -> AuthSignUpOperation

    /// Confirms the `signUp` operation.
    ///
    /// Invoke this operation as a follow up for the signUp process if the authentication provider
    /// that you are using required to follow a next step after signUp. Calling this operation without
    /// first calling `signUp` or `resendSignUpCode` may cause an error.
    /// - Parameters:
    ///   - username: Username used that was used to signUp.
    ///   - confirmationCode: Confirmation code received to the user.
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func confirmSignUp(for username: String,
                       confirmationCode: String,
                       options: AuthConfirmSignUpOperation.Request.Options?,
                       listener: AuthConfirmSignUpOperation.ResultListener?) -> AuthConfirmSignUpOperation

    /// Resends the confirmation code to confirm the signUp process
    ///
    /// - Parameters:
    ///   - username: Username of the user to be confirmed.
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func resendSignUpCode(for username: String,
                          options: AuthResendSignUpCodeOperation.Request.Options?,
                          listener: AuthResendSignUpCodeOperation.ResultListener?) -> AuthResendSignUpCodeOperation

    /// SignIn to the authentication provider
    ///
    /// Username and password are optional values, check the plugin documentation to decide on what all values need to
    /// passed. For example in a passwordless flow you just need to pass the username and the passwordcould be nil.
    ///
    /// - Parameters:
    ///   - username: Username to signIn the user
    ///   - password: Password to signIn the user
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes.
    func signIn(username: String?,
                password: String?,
                options: AuthSignInRequest.Options?) async throws -> AuthSignInResult

#if canImport(AuthenticationServices)
    /// SignIn using pre configured web UI.
    ///
    /// Calling this method will always launch the Auth plugin's default web user interface
    ///
    /// - Parameters:
    ///   - presentationAnchor: Anchor on which the UI is presented.
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor,
                         options: AuthWebUISignInOperation.Request.Options?,
                         listener: AuthWebUISignInOperation.ResultListener?) -> AuthWebUISignInOperation

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
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func signInWithWebUI(for authProvider: AuthProvider,
                         presentationAnchor: AuthUIPresentationAnchor,
                         options: AuthSocialWebUISignInOperation.Request.Options?,
                         listener: AuthSocialWebUISignInOperation.ResultListener?) -> AuthSocialWebUISignInOperation
#endif

    /// Confirms a next step in signIn flow.
    ///
    /// - Parameters:
    ///   - challengeResponse: Challenge response required to confirm the next step in signIn flow
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func confirmSignIn(challengeResponse: String,
                       options: AuthConfirmSignInOperation.Request.Options?,
                       listener: AuthConfirmSignInOperation.ResultListener?) -> AuthConfirmSignInOperation

    /// Sign out the currently logged-in user.
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior.
    ///   - listener: Triggered when the operation completes.
    /// - Returns: AuthSignOutOperation
    @discardableResult
    func signOut(options: AuthSignOutOperation.Request.Options?,
                 listener: AuthSignOutOperation.ResultListener?) -> AuthSignOutOperation

    /// Delete the account of the currently logged-in user.
    ///
    func deleteUser() async throws

    /// Fetch the current authentication session.
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func fetchAuthSession(options: AuthFetchSessionOperation.Request.Options?,
                          listener: AuthFetchSessionOperation.ResultListener?) -> AuthFetchSessionOperation

    /// Initiate a reset password flow for the user
    ///
    /// - Parameters:
    ///   - username: username whose password need to reset
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes
    @discardableResult
    func resetPassword(for username: String,
                       options: AuthResetPasswordOperation.Request.Options?,
                       listener: AuthResetPasswordOperation.ResultListener?) -> AuthResetPasswordOperation

    /// Confirms a reset password flow
    ///
    /// - Parameters:
    ///   - username: username whose password need to reset
    ///   - newPassword: new password for the user
    ///   - confirmationCode: Received confirmation code
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes
    @discardableResult
    func confirmResetPassword(for username: String,
                              with newPassword: String,
                              confirmationCode: String,
                              options: AuthConfirmResetPasswordOperation.Request.Options?,
                              listener: AuthConfirmResetPasswordOperation.ResultListener?)
    -> AuthConfirmResetPasswordOperation

}
