//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin

class MockAuthorizationProviderBehavior: AuthorizationProviderBehavior {

    var interactions: [String] = []

    // swiftlint:disable line_length
    var fetchSessionHandler: (AuthFetchSessionRequest, (Result<AuthSession, AuthError>) -> Void) -> Void = { _, completion in
        completion(.success(MockAuthSession(isSignedIn: true, tokens: .success(MockAuthCognitoTokens()))))
    }

    func fetchSession(request: AuthFetchSessionRequest,
                      completionHandler: @escaping (Result<AuthSession, AuthError>) -> Void) {
        interactions.append(#function)
        fetchSessionHandler(request, completionHandler)
    }

    func invalidateCachedTemporaryCredentials() {
        interactions.append(#function)
    }
}
