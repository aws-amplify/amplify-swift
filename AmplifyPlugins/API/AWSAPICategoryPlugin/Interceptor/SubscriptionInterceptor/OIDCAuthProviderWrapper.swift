//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AppSyncRealTimeClient

class OIDCAuthProviderWrapper: OIDCAuthProvider {

    let authTokenProvider: AmplifyAuthTokenProvider

    public init(authTokenProvider: AmplifyAuthTokenProvider) {
        self.authTokenProvider = authTokenProvider
    }

    func getLatestAuthToken() -> Result<String, Error> {
        return authTokenProvider.getLatestAuthToken()
    }
}
