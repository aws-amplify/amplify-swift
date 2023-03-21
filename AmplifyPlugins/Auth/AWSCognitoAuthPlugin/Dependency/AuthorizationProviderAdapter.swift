//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

typealias SessionCompletionHandler = (Result<AuthSession, AuthError>) -> Void

class AuthorizationProviderAdapter: AuthorizationProviderBehavior {

    let awsMobileClient: AWSMobileClientBehavior

    init(awsMobileClient: AWSMobileClientBehavior) {
        self.awsMobileClient = awsMobileClient
        setupListener()
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
        @unknown default:
            fetchSignedOutSession(completionHandler)
        }
    }

    func invalidateCachedTemporaryCredentials() {
        awsMobileClient.invalidateCachedTemporaryCredentials()
    }

    private func setupListener() {
        awsMobileClient.addUserStateListener(self) { [weak self] state, _ in
            guard let self = self else {
                return
            }
            Amplify.Logging.info("AWSMobileClient Event listener - \(state)")
            switch state {
            case .signedOutFederatedTokensInvalid,
                 .signedOutUserPoolsTokenInvalid:
                // These two state are returned when the session expired. It is safe to call releaseSignInWait from here
                // because AWSMobileClient had just locked the signIn state before sending out this state. This will
                // fail if someone else is listening to the state and called releaseSignInWait, signOut or signIn apis
                // of awsmobileclient.
                self.awsMobileClient.releaseSignInWait()
            default:
                break
            }
        }
    }
}
