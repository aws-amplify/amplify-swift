//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

extension RemoteSyncEngine: AuthModeStrategyDelegate {
    func isUserLoggedIn() -> Bool {
        // if OIDC is used as authentication provider
        // use `getLatestAuthToken`
        var isLoggedInWithOIDC = false

        if let authProviderFactory = api as? APICategoryAuthProviderFactoryBehavior,
           let oidcAuthProvider = authProviderFactory.apiAuthProviderFactory().oidcAuthProvider() {
            switch oidcAuthProvider.getLatestAuthToken() {
            case .failure:
                isLoggedInWithOIDC = false
            case .success:
                isLoggedInWithOIDC = true
            }

            return isLoggedInWithOIDC
        }

        let isSignedIn = auth?.getCurrentUser() != nil
        return isSignedIn
    }
}
