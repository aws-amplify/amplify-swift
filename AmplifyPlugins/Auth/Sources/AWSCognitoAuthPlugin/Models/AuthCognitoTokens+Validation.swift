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
    
    func areTokensExpiring(in seconds: TimeInterval? = nil) -> Bool {
        
        guard let idTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: idToken).get(),
              let accessTokenClaims = try? AWSAuthService().getTokenClaims(tokenString: accessToken).get(),
              let idTokenExpiration = idTokenClaims["exp"]?.doubleValue,
              let accessTokenExpiration = accessTokenClaims["exp"]?.doubleValue else {
            return true
        }
        
        // If the session expires < X minutes return it
        return (Date(timeIntervalSince1970: idTokenExpiration).compare(Date(timeIntervalSinceNow: seconds ?? 0)) == .orderedDescending &&
                Date(timeIntervalSince1970: accessTokenExpiration).compare(Date(timeIntervalSinceNow: seconds ?? 0)) == .orderedDescending)
    }
    
}
