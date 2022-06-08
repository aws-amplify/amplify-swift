//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

/// Internal Helpers for managing session tokens
extension AuthCognitoTokens {

    func areTokensExpiring(in seconds: TimeInterval = 0) -> Bool {

        guard let idTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: idToken).get(),
              let accessTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: accessToken).get(),
              let idTokenExpiration = idTokenClaims["exp"]?.doubleValue,
              let accessTokenExpiration = accessTokenClaims["exp"]?.doubleValue else {
            return true
        }

        let idTokenExpiry = Date(timeIntervalSince1970: idTokenExpiration)
        let accessTokenExpiry = Date(timeIntervalSince1970: accessTokenExpiration)

        let expiryTime = Date(timeIntervalSinceNow: seconds)
        return (idTokenExpiry.compare(expiryTime) == .orderedDescending &&
                accessTokenExpiry.compare(expiryTime) == .orderedDescending)
    }

}
