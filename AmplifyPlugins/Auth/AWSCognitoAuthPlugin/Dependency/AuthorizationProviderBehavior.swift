//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol AuthorizationProviderBehavior {

    func fetchSession(request: AuthFetchSessionRequest,
                      completionHandler: @escaping (Result<AuthSession, AuthError>) -> Void)

    func invalidateCachedTemporaryCredentials()
}
