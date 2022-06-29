//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

extension AuthResendSignUpCodeRequest {

    func hasError() -> AuthError? {
        guard !username.isEmpty else {
            return AuthError.validation(AuthPluginErrorConstants.resendSignUpCodeUsernameError.field,
                                        AuthPluginErrorConstants.resendSignUpCodeUsernameError.errorDescription,
                                        AuthPluginErrorConstants.resendSignUpCodeUsernameError.recoverySuggestion)
        }
        return nil
    }
}
