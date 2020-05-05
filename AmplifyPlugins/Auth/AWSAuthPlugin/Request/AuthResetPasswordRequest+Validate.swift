//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthResetPasswordRequest {

    func hasError() -> AmplifyAuthError? {
        guard !username.isEmpty else {
            return AmplifyAuthError.validation(
                AuthPluginErrorConstants.resetPasswordUsernameError.field,
                AuthPluginErrorConstants.resetPasswordUsernameError.errorDescription,
                AuthPluginErrorConstants.resetPasswordUsernameError.recoverySuggestion)
        }
        return nil
    }
}
