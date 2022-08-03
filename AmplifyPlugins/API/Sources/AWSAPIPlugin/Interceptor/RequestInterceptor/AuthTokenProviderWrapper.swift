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
    
    func getUserPoolAccessToken() async throws -> String {
        try await wrappedAuthTokenProvider.getUserPoolAccessToken()
    }
}
