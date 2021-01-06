//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthConfirmSignUpRequest {

    func hasError() -> AuthError? {
        guard !username.isEmpty else {
            return AuthError.validation(AuthPluginErrorConstants.confirmSignUpUsernameError.field,
                                               AuthPluginErrorConstants.confirmSignUpUsernameError.errorDescription,
                                               AuthPluginErrorConstants.confirmSignUpUsernameError.recoverySuggestion)
        }

        guard !code.isEmpty else {
            return AuthError.validation(AuthPluginErrorConstants.confirmSignUpCodeError.field,
                                               AuthPluginErrorConstants.confirmSignUpCodeError.errorDescription,
                                               AuthPluginErrorConstants.confirmSignUpCodeError.recoverySuggestion)
        }

        return nil
    }
}
