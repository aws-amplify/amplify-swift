//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public enum AWSCognitoSignOutResult: AuthSignOutResult {

    case complete

    case partial(revokeTokenError: AWSCognitoRevokeTokenError?,
                 globalSignOutError: AWSCognitoGlobalSignOutError?,
                 hostedUIError: AWSCognitoHostedUIError?)

    case failed(AuthError)
}

public struct AWSCognitoRevokeTokenError {
    let refreshToken: String
    let error: AuthError
}

public struct AWSCognitoGlobalSignOutError {
    let accessToken: String
    let error: AuthError
}

public struct AWSCognitoHostedUIError {
    let error: AuthError
}
