//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthSignInRequest {

    func hasError() -> AuthError? {
        guard let username = self.username, !username.isEmpty else {
            return AuthError.validation(AuthPluginErrorConstants.signInUsernameError.field,
                                               AuthPluginErrorConstants.signInUsernameError.errorDescription,
                                               AuthPluginErrorConstants.signInUsernameError.recoverySuggestion)
        }
        return nil
    }

}
