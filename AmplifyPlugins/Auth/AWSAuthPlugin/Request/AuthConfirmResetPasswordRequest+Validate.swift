//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthConfirmResetPasswordRequest {

    func hasError() -> AmplifyAuthError? {
        guard !username.isEmpty else {
            return AmplifyAuthError.validation(
                AuthPluginErrorConstants.confirmResetPasswordUsernameError.field,
                AuthPluginErrorConstants.confirmResetPasswordUsernameError.errorDescription,
                AuthPluginErrorConstants.confirmResetPasswordUsernameError.recoverySuggestion)
        }
        guard !newPassword.isEmpty else {
            return AmplifyAuthError.validation(
                AuthPluginErrorConstants.confirmResetPasswordNewPasswordError.field,
                AuthPluginErrorConstants.confirmResetPasswordNewPasswordError.errorDescription,
                AuthPluginErrorConstants.confirmResetPasswordNewPasswordError.recoverySuggestion)
        }
        guard !confirmationCode.isEmpty else {
            return AmplifyAuthError.validation(
                AuthPluginErrorConstants.confirmResetPasswordCodeError.field,
                AuthPluginErrorConstants.confirmResetPasswordCodeError.errorDescription,
                AuthPluginErrorConstants.confirmResetPasswordCodeError.recoverySuggestion)
        }
        return nil
    }
}
