//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

class AuthTokenProviderWrapper: AuthTokenProvider {

    let wrappedAuthTokenProvider: AmplifyAuthTokenProvider

    init(tokenAuthProvider: AmplifyAuthTokenProvider) {
        self.wrappedAuthTokenProvider = tokenAuthProvider
    }

    @available(*, deprecated, renamed: "getUserPoolAccessToken")
    func getToken() -> Result<String, AuthError> {
        let result = wrappedAuthTokenProvider.getLatestAuthToken()
        switch result {
        case .success(let result):
            return .success(result)
        case .failure(let error):
            return .failure(AuthError.service("Unable to get latest auth token",
                                              "",
                                              error))
        }
    }
    
    func getUserPoolAccessToken() async throws -> String {
        try await wrappedAuthTokenProvider.getUserPoolAccessToken()
    }
    
    func getUserPoolAccessToken() async throws -> String {
        try await wrappedAuthTokenProvider.getUserPoolAccessToken()
    }
}
