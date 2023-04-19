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

    func getToken(completion: @escaping (Result<String, AuthError>) -> Void) {
        wrappedAuthTokenProvider.getLatestAuthToken { result in
            switch result {
            case .success(let token):
                completion(.success(token))
                return
            case .failure(let error):
                completion(.failure(AuthError.service("Unable to get latest auth token",
                                                      "",
                                                      error)))
                return
            }
        }
    }

}
