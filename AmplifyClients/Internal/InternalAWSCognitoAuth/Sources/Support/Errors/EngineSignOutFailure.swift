//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// The engine's sign-out failure payloads, carried by `SignOutEvent` and `SignedOutData`. They mirror the
// plugin's public `AWSCognitoRevokeTokenError`, `AWSCognitoGlobalSignOutError` and `AWSCognitoHostedUIError`
// (`AWSCognitoSignOutResult.swift`) field for field, with `EngineAuthError` in place of `AuthError`. The
// plugin's sign-out task converts them when it builds `AWSCognitoSignOutResult.partial`.

/// Revoking the refresh token failed; sign-out continued locally.
package struct EngineRevokeTokenFailure: Sendable {
    package let refreshToken: String
    package let error: EngineAuthError

    package init(refreshToken: String, error: EngineAuthError) {
        self.refreshToken = refreshToken
        self.error = error
    }
}

/// Global sign-out failed; sign-out continued with revoking the token.
package struct EngineGlobalSignOutFailure: Sendable {
    package let accessToken: String
    package let error: EngineAuthError

    package init(accessToken: String, error: EngineAuthError) {
        self.accessToken = accessToken
        self.error = error
    }
}

extension EngineRevokeTokenFailure: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// The default struct printing, with the refresh token masked as the plugin's `AWSCognitoRevokeTokenError`
    /// masks it: the token is still valid when revoking it failed.
    package var description: String {
        let token = String(reflecting: refreshToken.maskedForLog(interiorCount: 5))
        return "\(String(reflecting: Self.self))(refreshToken: \(token), error: \(String(reflecting: error)))"
    }

    package var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the error, and the refresh token masked.
    package var customMirror: Mirror {
        Mirror(self, children: ["refreshToken": refreshToken.maskedForLog(interiorCount: 5), "error": error], displayStyle: .struct)
    }
}

extension EngineGlobalSignOutFailure: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    /// The default struct printing, with the access token masked as the plugin's `AWSCognitoGlobalSignOutError`
    /// masks it: the token is still valid when global sign-out failed.
    package var description: String {
        let token = String(reflecting: accessToken.maskedForLog(interiorCount: 5))
        return "\(String(reflecting: Self.self))(accessToken: \(token), error: \(String(reflecting: error)))"
    }

    package var debugDescription: String {
        description
    }

    /// For `dump` and debuggers: the error, and the access token masked.
    package var customMirror: Mirror {
        Mirror(self, children: ["accessToken": accessToken.maskedForLog(interiorCount: 5), "error": error], displayStyle: .struct)
    }
}

/// Hosted UI sign-out failed; sign-out continued without it.
package struct EngineHostedUISignOutFailure: Sendable {
    package let error: EngineAuthError

    package init(error: EngineAuthError) {
        self.error = error
    }
}
