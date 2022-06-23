

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

extension AuthConfirmSignInRequest {

    func hasError() -> AuthError? {
        guard !challengeResponse.isEmpty else {
            return AuthError.validation(AuthPluginErrorConstants.confirmSignInChallengeResponseError.field,
                                        AuthPluginErrorConstants.confirmSignInChallengeResponseError.errorDescription,
                                        AuthPluginErrorConstants.confirmSignInChallengeResponseError.recoverySuggestion)
        }
        return nil
    }
}
