//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockAuthCategoryPlugin {
    struct Responders {
        // AuthN
        var confirmResetPassword: ConfirmResetPasswordResponder?
        var confirmSignIn: ConfirmSignInResponder?
        var confirmSignUp: ConfirmSignUpResponder?
        var fetchAuthSession: FetchAuthSessionResponder?
        var resendSignUpCode: ResendSignUpCodeResponder?
        var resetPassword: ResetPasswordResponder?
        var signIn: SignInResponder?
        var signInWithWebUI: SignInWithWebUIResponder?
        var signInWithWebUIForAuthProvider: SignInWithWebUIForAuthProviderResponder?
        var signOut: SignOutResponder?
        var signUp: SignUpResponder?

        // User behavior
        var confirmUserAttribute: ConfirmUserAttributeResponder?
        var fetchUserAttributes: FetchUserAttributesResponder?
        var resendConfirmationCode: ResendConfirmationCodeResponder?
        var updatePassword: UpdatePasswordResponder?
        var updateUserAttribute: UpdateUserAttributeResponder?
        var updateUserAttributes: UpdateUserAttributesResponder?

        // Device behavior
        var fetchDevices: FetchDevicesResponder?
        var forgetDevice: ForgetDeviceResponder?
        var rememberDevice: RememberDeviceResponder?
    }
}

// MARK: - AuthN

typealias ConfirmResetPasswordResponder = (
    String,
    String,
    String,
    AuthConfirmResetPasswordOperation.Request.Options?
) -> AuthConfirmResetPasswordOperation.OperationResult

typealias ConfirmSignInResponder = (
    String,
    AuthConfirmSignInOperation.Request.Options?
) -> AuthConfirmSignInOperation.OperationResult

typealias ConfirmSignUpResponder = (
    String,
    String,
    AuthConfirmSignUpOperation.Request.Options?
) -> AuthConfirmSignUpOperation.OperationResult

typealias FetchAuthSessionResponder = (
    AuthFetchSessionOperation.Request.Options?
) -> AuthFetchSessionOperation.OperationResult

typealias ResendSignUpCodeResponder = (
    String,
    AuthResendSignUpCodeOperation.Request.Options?
) -> AuthResendSignUpCodeOperation.OperationResult

typealias ResetPasswordResponder = (
    String,
    AuthResetPasswordOperation.Request.Options?
) -> AuthResetPasswordOperation.OperationResult

typealias SignInResponder = (
    String?,
    String?,
    AuthSignInOperation.Request.Options?
) -> AuthSignInOperation.OperationResult

typealias SignInWithWebUIResponder = (
    AuthUIPresentationAnchor,
    AuthWebUISignInOperation.Request.Options?
) -> AuthWebUISignInOperation.OperationResult

typealias SignInWithWebUIForAuthProviderResponder = (
    AuthProvider,
    AuthUIPresentationAnchor,
    AuthSocialWebUISignInOperation.Request.Options?
) -> AuthSocialWebUISignInOperation.OperationResult

typealias SignOutResponder = (
    AuthSignOutOperation.Request.Options?
) -> AuthSignOutOperation.OperationResult

typealias SignUpResponder = (
    String,
    String?,
    AuthSignUpOperation.Request.Options?
) -> AuthSignUpOperation.OperationResult

// MARK: - User behavior

typealias ConfirmUserAttributeResponder = (
    AuthUserAttributeKey,
    String,
    AuthConfirmUserAttributeOperation.Request.Options?
) -> AuthConfirmUserAttributeOperation.OperationResult

typealias FetchUserAttributesResponder = (
    AuthFetchUserAttributeOperation.Request.Options?
) -> AuthFetchUserAttributeOperation.OperationResult

typealias ResendConfirmationCodeResponder = (
    AuthUserAttributeKey,
    AuthAttributeResendConfirmationCodeOperation.Request.Options?
) -> AuthAttributeResendConfirmationCodeOperation.OperationResult

typealias UpdatePasswordResponder = (
    String,
    String,
    AuthChangePasswordOperation.Request.Options?
) -> AuthChangePasswordOperation.OperationResult

typealias UpdateUserAttributeResponder = (
    AuthUserAttribute,
    AuthUpdateUserAttributeOperation.Request.Options?
) -> AuthUpdateUserAttributeOperation.OperationResult

typealias UpdateUserAttributesResponder = (
    [AuthUserAttribute],
    AuthUpdateUserAttributesOperation.Request.Options?
) -> AuthUpdateUserAttributesOperation.OperationResult

// MARK: - Device behavior

typealias FetchDevicesResponder = (
    AuthFetchDevicesOperation.Request.Options?
) -> AuthFetchDevicesOperation.OperationResult

typealias ForgetDeviceResponder = (
    AuthDevice?,
    AuthForgetDeviceOperation.Request.Options?
) -> AuthForgetDeviceOperation.OperationResult

typealias RememberDeviceResponder = (
    AuthRememberDeviceOperation.Request.Options?
) -> AuthRememberDeviceOperation.OperationResult
