//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public enum AWSCognitoSignOutResult: AuthSignOutResult {

    public var signedOutLocally: Bool {
        if case .failed = self {
            return false
        }
        return true
    }

    case complete

    case partial(
        revokeTokenError: AWSCognitoRevokeTokenError?,
        globalSignOutError: AWSCognitoGlobalSignOutError?,
        hostedUIError: AWSCognitoHostedUIError?
    )

    case failed(AuthError)
}

extension AWSCognitoSignOutResult: Sendable { }

public struct AWSCognitoRevokeTokenError {
    public let refreshToken: String
    public let error: AuthError
}

extension AWSCognitoRevokeTokenError: Sendable { }

public struct AWSCognitoGlobalSignOutError {
    public let accessToken: String
    public let error: AuthError
}

extension AWSCognitoGlobalSignOutError: Sendable { }

public struct AWSCognitoHostedUIError {
    public let error: AuthError
}

extension AWSCognitoHostedUIError: Sendable { }
