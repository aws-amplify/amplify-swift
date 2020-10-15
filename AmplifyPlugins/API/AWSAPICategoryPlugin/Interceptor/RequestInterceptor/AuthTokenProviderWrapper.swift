//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

class AuthTokenProviderWrapper: AuthTokenProvider {

    let oidcAuthProvider: AmplifyOIDCAuthProvider

    init(oidcAuthProvider: AmplifyOIDCAuthProvider) {
        self.oidcAuthProvider = oidcAuthProvider
    }

    func getToken() -> Result<String, AuthError> {
        let result = oidcAuthProvider.getLatestAuthToken()
        switch result {
        case .success(let result):
            return .success(result)
        case .failure(let error):
            return .failure(AuthError.service("Unable to get latest auth token",
                                              "",
                                              error))
        }
    }

}
