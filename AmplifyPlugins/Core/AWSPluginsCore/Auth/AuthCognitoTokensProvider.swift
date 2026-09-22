//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public protocol AuthCognitoTokensProvider {
    func getCognitoTokens() -> Result<AuthCognitoTokens, AuthError>
}

/// - Note: `Sendable` because tokens are carried across task boundaries by the auth and API layers.
public protocol AuthCognitoTokens: Sendable {

    var idToken: String {get}

    var accessToken: String {get}

    var refreshToken: String {get}

}
