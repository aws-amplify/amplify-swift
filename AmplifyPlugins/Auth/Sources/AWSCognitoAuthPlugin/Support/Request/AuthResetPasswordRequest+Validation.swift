//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthResetPasswordRequest {

    func hasError() -> AuthError? {
        guard !username.isEmpty else {
            return AuthError.validation(
                AuthPluginErrorConstants.resetPasswordUsernameError.field,
                AuthPluginErrorConstants.resetPasswordUsernameError.errorDescription,
                AuthPluginErrorConstants.resetPasswordUsernameError.recoverySuggestion)
        }
        return nil
    }
}
