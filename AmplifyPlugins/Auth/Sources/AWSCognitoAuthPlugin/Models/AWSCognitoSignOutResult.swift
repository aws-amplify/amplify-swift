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

extension AWSCognitoRevokeTokenError: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// The default struct printing, with the refresh token masked as `AWSCognitoUserPoolTokens` masks it: a
    /// sign-out result is logged, and the token is still valid when revoking it failed.
    public var description: String {
        let token = String(reflecting: refreshToken.masked(interiorCount: 5))
        return "\(String(reflecting: Self.self))(refreshToken: \(token), error: \(String(reflecting: error)))"
    }

    public var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the error, and the refresh token masked.
    public var customMirror: Mirror {
        Mirror(self, children: ["refreshToken": refreshToken.masked(interiorCount: 5), "error": error], displayStyle: .struct)
    }
}

public struct AWSCognitoGlobalSignOutError {
    public let accessToken: String
    public let error: AuthError
}

extension AWSCognitoGlobalSignOutError: Sendable { }

extension AWSCognitoGlobalSignOutError: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// The default struct printing, with the access token masked as `AWSCognitoUserPoolTokens` masks it: a
    /// sign-out result is logged, and the token is still valid when global sign-out failed.
    public var description: String {
        let token = String(reflecting: accessToken.masked(interiorCount: 5))
        return "\(String(reflecting: Self.self))(accessToken: \(token), error: \(String(reflecting: error)))"
    }

    public var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the error, and the access token masked.
    public var customMirror: Mirror {
        Mirror(self, children: ["accessToken": accessToken.masked(interiorCount: 5), "error": error], displayStyle: .struct)
    }
}

public struct AWSCognitoHostedUIError {
    public let error: AuthError
}

extension AWSCognitoHostedUIError: Sendable { }
