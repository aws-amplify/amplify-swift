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

    func signOut(request: AuthSignOutRequest, completionHandler: @escaping (Result<Void, AuthError>) -> Void) {

        // If developer had signed in using private session, we just need to signout the user locally.
        guard !userdefaults.isPrivateSessionPreferred() else {
            awsMobileClient.signOutLocally()
            // Reset the user defaults.
            userdefaults.storePreferredBrowserSession(privateSessionPrefered: false)
            completionHandler(.success(()))
            return
        }

        // If user is signed in through HostedUI the signout require UI to complete. So calling this in main thread.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.signOutWithUI(isGlobalSignout: request.options.globalSignOut, completionHandler: completionHandler)
        }
    }

    private func signOutWithUI(isGlobalSignout: Bool, completionHandler: @escaping (Result<Void, AuthError>) -> Void) {

        // Stop the execution here if we are not running on the main thread.
        // There is no point on returning an error back to the developer, because
        // they do not control how the UI is presented.
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))

        let signOutOptions = SignOutOptions(signOutGlobally: isGlobalSignout, invalidateTokens: true)
        awsMobileClient.signOut(options: signOutOptions) { [weak self] error in
            guard let error = error else {
                completionHandler(.success(()))
                return
            }

            // If the user had cancelled the signOut flow by closing the HostedUI,
            // return userCancelled error.
            if AuthErrorHelper.didUserCancelHostedUI(error) {
                let signOutError = AuthError.service(
                    AuthPluginErrorConstants.hostedUIUserCancelledSignOutError.errorDescription,
                    AuthPluginErrorConstants.hostedUIUserCancelledSignOutError.recoverySuggestion,
                    AWSCognitoAuthError.userCancelled)
                completionHandler(.failure(signOutError))
                return
            }

            let authError = AuthErrorHelper.toAuthError(error)
            if case .notAuthorized = authError {
                // signOut globally might return notAuthorized when the current token is expired or invalidated
                // In this case, we just signOut the user locally and return a success result back.
                self?.awsMobileClient.signOutLocally()
                completionHandler(.success(()))
            } else {
                completionHandler(.failure(authError))
            }
            return
        }
    }
}
