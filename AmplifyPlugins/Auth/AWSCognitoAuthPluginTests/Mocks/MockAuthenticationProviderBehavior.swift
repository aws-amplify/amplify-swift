//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin

class MockAuthenticationProviderBehavior: AuthenticationProviderBehavior {

    var interactions: [String] = []

    var signUpHandler: (AuthSignUpRequest, (Result<AuthSignUpResult, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(AuthSignUpResult(.done)))
    }

    func signUp(request: AuthSignUpRequest,
                completionHandler: @escaping (Result<AuthSignUpResult, AuthError>) -> Void) {
        interactions.append(#function)
        signUpHandler(request, completionHandler)
    }

    // swiftlint:disable line_length
    var confirmSignUpHandler: (AuthConfirmSignUpRequest, (Result<AuthSignUpResult, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(AuthSignUpResult(.done)))
    }

    func confirmSignUp(request: AuthConfirmSignUpRequest,
                       completionHandler: @escaping (Result<AuthSignUpResult, AuthError>) -> Void) {
        interactions.append(#function)
        confirmSignUpHandler(request, completionHandler)
    }

    // swiftlint:disable line_length
    var resendSignUpCodeHandler: (AuthResendSignUpCodeRequest, (Result<AuthCodeDeliveryDetails, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(AuthCodeDeliveryDetails(destination: .email("user@example.com"))))
    }

    func resendSignUpCode(request: AuthResendSignUpCodeRequest,
                          completionHandler: @escaping (Result<AuthCodeDeliveryDetails, AuthError>) -> Void) {
        interactions.append(#function)
        resendSignUpCodeHandler(request, completionHandler)
    }

    var signInHandler: (AuthSignInRequest, (Result<AuthSignInResult, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(AuthSignInResult(nextStep: .done)))
    }

    func signIn(request: AuthSignInRequest,
                completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {
        interactions.append(#function)
        signInHandler(request, completionHandler)
    }

    // swiftlint:disable line_length
    var signInWithWebUIHandler: (AuthWebUISignInRequest, (Result<AuthSignInResult, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(AuthSignInResult(nextStep: .done)))
    }

    func signInWithWebUI(request: AuthWebUISignInRequest,
                         completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {
        interactions.append(#function)
        signInWithWebUIHandler(request, completionHandler)
    }

    // swiftlint:disable line_length
    var confirmSignInHandler: (AuthConfirmSignInRequest, (Result<AuthSignInResult, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(AuthSignInResult(nextStep: .done)))
    }

    func confirmSignIn(request: AuthConfirmSignInRequest,
                       completionHandler: @escaping (Result<AuthSignInResult, AuthError>) -> Void) {
        interactions.append(#function)
        confirmSignInHandler(request, completionHandler)
    }

    var signOutHandler: (AuthSignOutRequest, (Result<Void, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(()))
    }

    func signOut(request: AuthSignOutRequest,
                 completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        interactions.append(#function)
        signOutHandler(request, completionHandler)
    }

    var deleteUserHandler: (AuthDeleteUserRequest, (Result<Void, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(()))
    }

    func deleteUser(request: AuthDeleteUserRequest,
                    completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        interactions.append(#function)
        deleteUserHandler(request, completionHandler)
    }

    var authUser: AuthUser?

    func getCurrentUser() -> AuthUser? {
        interactions.append(#function)
        return authUser
    }

    // swiftlint:disable line_length
    var resetPasswordHandler: (AuthResetPasswordRequest, (Result<AuthResetPasswordResult, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(AuthResetPasswordResult(isPasswordReset: true, nextStep: .done)))
    }

    func resetPassword(request: AuthResetPasswordRequest,
                       completionHandler: @escaping (Result<AuthResetPasswordResult, AuthError>) -> Void) {
        interactions.append(#function)
        resetPasswordHandler(request, completionHandler)
    }

    // swiftlint:disable line_length
    var confirmResetPasswordHandler: (AuthConfirmResetPasswordRequest, (Result<Void, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(()))
    }

    func confirmResetPassword(request: AuthConfirmResetPasswordRequest,
                              completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        interactions.append(#function)
        confirmResetPasswordHandler(request, completionHandler)
    }
}
