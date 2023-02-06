////
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

/// Placeholder implementation of the [AuthCategoryPlugin](x-source-tag://AuthCategoryPlugin)
/// protocol. This plugin will throw an error for all functional features of the category.
///
/// - Tag: AuthCategoryPluginPlaceholder
final class AuthCategoryPluginPlaceholder {
    struct PluginError: Error, CustomStringConvertible {
        var description: String
    }
}

extension AuthCategoryPluginPlaceholder: AuthCategoryPlugin {

    var key: PluginKey {
        return "AuthCategoryPluginPlaceholder"
    }

    func configure(using configuration: Any?) throws {
    }

    func signUp(username: String, password: String?, options: AuthSignUpRequest.Options?) async throws -> AuthSignUpResult {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func confirmSignUp(for username: String, confirmationCode: String, options: AuthConfirmSignUpRequest.Options?) async throws -> AuthSignUpResult {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func resendSignUpCode(for username: String, options: AuthResendSignUpCodeRequest.Options?) async throws -> AuthCodeDeliveryDetails {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func signIn(username: String?, password: String?, options: AuthSignInRequest.Options?) async throws -> AuthSignInResult {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func signInWithWebUI(presentationAnchor: AuthUIPresentationAnchor?, options: AuthWebUISignInRequest.Options?) async throws -> AuthSignInResult {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func signInWithWebUI(for authProvider: AuthProvider, presentationAnchor: AuthUIPresentationAnchor?, options: AuthWebUISignInRequest.Options?) async throws -> AuthSignInResult {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func confirmSignIn(challengeResponse: String, options: AuthConfirmSignInRequest.Options?) async throws -> AuthSignInResult {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func signOut(options: AuthSignOutRequest.Options?) async -> AuthSignOutResult {
        enum AuthSignOutResultError: AuthSignOutResult {
            case placeholder(PlaceholderPluginError)
        }
        return AuthSignOutResultError.placeholder(
            PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
        )
    }

    func deleteUser() async throws {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func fetchAuthSession(options: AuthFetchSessionRequest.Options?) async throws -> AuthSession {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func resetPassword(for username: String, options: AuthResetPasswordRequest.Options?) async throws -> AuthResetPasswordResult {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func confirmResetPassword(for username: String, with newPassword: String, confirmationCode: String, options: AuthConfirmResetPasswordRequest.Options?) async throws {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func reset() async {
    }

    func getCurrentUser() async throws -> AuthUser {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func fetchUserAttributes(options: AuthFetchUserAttributesRequest.Options?) async throws -> [AuthUserAttribute] {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func update(userAttribute: AuthUserAttribute, options: AuthUpdateUserAttributeRequest.Options?) async throws -> AuthUpdateAttributeResult {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func update(userAttributes: [AuthUserAttribute], options: AuthUpdateUserAttributesRequest.Options?) async throws -> [AuthUserAttributeKey : AuthUpdateAttributeResult] {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func resendConfirmationCode(forUserAttributeKey userAttributeKey: AuthUserAttributeKey, options: AuthAttributeResendConfirmationCodeRequest.Options?) async throws -> AuthCodeDeliveryDetails {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func confirm(userAttribute: AuthUserAttributeKey, confirmationCode: String, options: AuthConfirmUserAttributeRequest.Options?) async throws {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func update(oldPassword: String, to newPassword: String, options: AuthChangePasswordRequest.Options?) async throws {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func fetchDevices(options: AuthFetchDevicesRequest.Options?) async throws -> [AuthDevice] {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func forgetDevice(_ device: AuthDevice?, options: AuthForgetDeviceRequest.Options?) async throws {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }

    func rememberDevice(options: AuthRememberDeviceRequest.Options?) async throws {
        throw PlaceholderPluginError(pluginName: "AuthCategoryPlugin", selector: #function)
    }
}
