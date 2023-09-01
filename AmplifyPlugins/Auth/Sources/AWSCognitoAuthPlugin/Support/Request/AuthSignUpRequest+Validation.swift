//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthSignUpRequest {

    func hasError() throws {
        guard !username.isEmpty else {
            let error = AuthError.validation(
                AuthPluginErrorConstants.signUpUsernameError.field,
                AuthPluginErrorConstants.signUpUsernameError.errorDescription,
                AuthPluginErrorConstants.signUpUsernameError.recoverySuggestion, nil)
            throw error
        }
    }
}
