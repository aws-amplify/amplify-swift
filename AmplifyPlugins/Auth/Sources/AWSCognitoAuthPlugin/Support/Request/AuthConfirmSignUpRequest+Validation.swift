//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthConfirmSignUpRequest {

    func hasError() throws {

        guard !username.isEmpty else {
            let error = AuthError.validation(
                AuthPluginErrorConstants.signUpUsernameError.field,
                AuthPluginErrorConstants.signUpUsernameError.errorDescription,
                AuthPluginErrorConstants.signUpUsernameError.recoverySuggestion, nil)
            throw error
        }

        guard !code.isEmpty else {
               let error = AuthError.validation(
                AuthPluginErrorConstants.confirmSignUpCodeError.field,
                AuthPluginErrorConstants.confirmSignUpCodeError.errorDescription,
                AuthPluginErrorConstants.confirmSignUpCodeError.recoverySuggestion, nil)
           throw error
        }
    }
}
