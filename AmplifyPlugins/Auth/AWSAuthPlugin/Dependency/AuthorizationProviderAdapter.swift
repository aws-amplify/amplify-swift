//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

typealias SessionCompletionHandler = (Result<AuthSession, AuthError>) -> Void

class AuthorizationProviderAdapter: AuthorizationProviderBehavior {

    let awsMobileClient: AWSMobileClientBehavior

    init(awsMobileClient: AWSMobileClientBehavior) {
        self.awsMobileClient = awsMobileClient
    }

    func fetchSession(request: AuthFetchSessionRequest,
                      completionHandler: @escaping SessionCompletionHandler) {

        switch awsMobileClient.getCurrentUserState() {
        case .guest:
            fetchSignedOutSession(completionHandler)
        case .signedIn,
             .signedOutFederatedTokensInvalid,
             .signedOutUserPoolsTokenInvalid:
            fetchSignedInSession(completionHandler)
        case .signedOut,
             .unknown:
            fetchSignedOutSession(completionHandler)
        }
    }

    func invalidateCachedTemporaryCredentials() {
        awsMobileClient.invalidateCachedTemporaryCredentials()
    }
}
