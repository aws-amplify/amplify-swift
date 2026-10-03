//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

/// Password reset, with the plugin's semantics. A reset acts on a username, not on the session's user, so it
/// runs whether or not this session is signed in, changes nothing in it, and reads no saved record.
///
/// Each call validates its arguments first, with the plugin's messages, and sends nothing when one is empty.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// Starts a password reset: Cognito sends the user a code.
    ///
    /// - Returns: `.confirmResetPasswordWithCode` with where the code was sent. A pool that prevents
    ///   user-existence errors answers the same for an unknown user.
    /// - Throws: `AuthClientError.validation` for an empty username; `.configuration` without a user pool;
    ///   `.service` as Cognito answers, such as `.limitExceeded`; `.notAuthorized` when the user pool refuses
    ///   the reset (a disabled user, for example); `.unknown` for a failure the client does not recognise, or an
    ///   answer without delivery details; `CancellationError` if the calling task is cancelled.
    func resetPassword(
        for username: String,
        options: AuthClientResetPasswordOptions = AuthClientResetPasswordOptions()
    ) async throws -> AuthClientResetPasswordResult {
        try Self.requireResetPasswordArgument(username, AuthPluginErrorConstants.resetPasswordUsernameError)
        let clientMetadata = options.clientMetadata
        let core = core
        return try await core.userPoolOperation("reset a password") { engine in
            try await engine.resetPassword(username: username, clientMetadata: clientMetadata)
        }
    }

    /// Completes a password reset with the code Cognito sent.
    ///
    /// - Throws: `AuthClientError.validation` for an empty username, new password or code, checked in that
    ///   order; `.configuration` without a user pool; `.service` as Cognito answers, such as `.codeMismatch` or
    ///   `.invalidPassword`; `.notAuthorized` when the user pool refuses the reset; `.unknown` for a failure the
    ///   client does not recognise; `CancellationError` if the calling task is cancelled.
    func confirmResetPassword(
        for username: String,
        with newPassword: String,
        confirmationCode: String,
        options: AuthClientConfirmResetPasswordOptions = AuthClientConfirmResetPasswordOptions()
    ) async throws {
        try Self.requireResetPasswordArgument(username, AuthPluginErrorConstants.confirmResetPasswordUsernameError)
        try Self.requireResetPasswordArgument(newPassword, AuthPluginErrorConstants.confirmResetPasswordNewPasswordError)
        try Self.requireResetPasswordArgument(confirmationCode, AuthPluginErrorConstants.confirmResetPasswordCodeError)
        let request = EngineConfirmResetPasswordRequest(
            username: username,
            newPassword: newPassword,
            confirmationCode: confirmationCode,
            clientMetadata: options.clientMetadata
        )
        let core = core
        try await core.userPoolOperation("confirm a password reset") { engine in
            try await engine.confirmResetPassword(request)
        }
    }
}

extension AmplifyCognitoClient {

    /// Throws `validation` for an empty `value`, before any request is sent: the plugin's
    /// `AuthResetPasswordRequest.hasError()` and `AuthConfirmResetPasswordRequest.hasError()`, string for
    /// string.
    static func requireResetPasswordArgument(_ value: String, _ rule: AuthPluginValidationErrorString) throws {
        guard value.isEmpty else {
            return
        }
        throw AuthClientError.validation(field: rule.field, rule.errorDescription, rule.recoverySuggestion)
    }
}
