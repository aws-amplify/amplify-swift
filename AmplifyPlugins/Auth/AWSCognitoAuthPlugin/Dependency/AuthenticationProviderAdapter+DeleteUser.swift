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

extension AuthenticationProviderAdapter {

    func deleteUser(request: AuthDeleteUserRequest, completionHandler: @escaping (Result<Void, AuthError>) -> Void) {
        awsMobileClient.deleteUser { [weak self] error in
            guard let error = error else {
                if let self = self, self.userdefaults.isPrivateSessionPreferred() {
                    // Reset the user defaults.
                    self.userdefaults.storePreferredBrowserSession(privateSessionPrefered: false)
                }

                completionHandler(.success(()))
                Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: HubPayload.EventName.Auth.signedOut))
                return
            }

            if case .notSignedIn = error as? AWSMobileClientError {
                let authError = AuthError.signedOut(AuthPluginErrorConstants.deleteUserSignOutError.errorDescription,
                                                    AuthPluginErrorConstants.deleteUserSignOutError.recoverySuggestion,
                                                    error)
                completionHandler(.failure(authError))
            } else {
                completionHandler(.failure(AuthErrorHelper.toAuthError(error)))
            }
        }
    }
}
