//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthSignUpRequest {

    func hasError() -> AuthError? {
        guard !username.isEmpty else {
            return AuthError.validation(AuthPluginErrorConstants.signUpUsernameError.field,
                                               AuthPluginErrorConstants.signUpUsernameError.errorDescription,
                                               AuthPluginErrorConstants.signUpUsernameError.recoverySuggestion)
        }

        guard let password = password, !password.isEmpty else {
            return AuthError.validation(AuthPluginErrorConstants.signUpPasswordError.field,
                                               AuthPluginErrorConstants.signUpPasswordError.errorDescription,
                                               AuthPluginErrorConstants.signUpPasswordError.recoverySuggestion)
        }

        return nil
    }
}
