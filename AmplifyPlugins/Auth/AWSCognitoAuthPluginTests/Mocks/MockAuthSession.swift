//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

struct MockAuthSession: AuthSession, AuthCognitoTokensProvider {
    var isSignedIn: Bool
    var tokens: Result<AuthCognitoTokens, AuthError>
    func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError> {
        return tokens
    }
}
