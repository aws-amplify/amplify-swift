//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin

class MockAuthorizationProviderBehavior: AuthorizationProviderBehavior {
    func fetchSession(request: AuthFetchSessionRequest,
                      completionHandler: @escaping (Result<AuthSession, AuthError>) -> Void) {
        // Incomplete implementation
    }

    func invalidateCachedTemporaryCredentials() {
        // Incomplete implementation
    }
}
