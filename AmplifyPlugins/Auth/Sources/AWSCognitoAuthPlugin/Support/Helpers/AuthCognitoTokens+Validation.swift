//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Foundation

/// Internal Helpers for managing session tokens
extension AWSCognitoUserPoolTokens {

    func doesExpire(in seconds: TimeInterval = 0) -> Bool {

        guard let idTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: idToken).get(),
              let accessTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: accessToken).get(),
              let idTokenExpiration = idTokenClaims["exp"]?.doubleValue,
              let accessTokenExpiration = accessTokenClaims["exp"]?.doubleValue
        else {
            // If token parsing fails, return as expired, to just force refresh
            return true
        }

        let idTokenExpiry = Date(timeIntervalSince1970: idTokenExpiration)
        let accessTokenExpiry = Date(timeIntervalSince1970: accessTokenExpiration)

        let currentTime = Date(timeIntervalSinceNow: seconds)
        return currentTime > idTokenExpiry || currentTime > accessTokenExpiry
    }

}
