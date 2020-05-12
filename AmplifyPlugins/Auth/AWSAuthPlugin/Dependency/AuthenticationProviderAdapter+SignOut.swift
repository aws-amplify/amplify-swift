//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

extension AuthenticationProviderAdapter {

    func signOut(request: AuthSignOutRequest, completionHandler: @escaping (Result<Void, AuthError>) -> Void) {

        // If user is signed in through HostedUI the signout require UI to complete. So calling this in main thread.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.signOutWithUI(completionHandler)
        }
    }

    private func signOutWithUI(_ completionHandler: @escaping (Result<Void, AuthError>) -> Void) {

        // Stop the execution here if we are not running on the main thread.
        // There is no point on returning an error back to the developer, because
        // they do not control how the UI is presented.
        dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
        let signOutOptions = SignOutOptions(signOutGlobally: true, invalidateTokens: true)
        awsMobileClient.signOut(options: signOutOptions) { error in
            guard error == nil else {
                let authError = AuthErrorHelper.toAuthError(error!)
                completionHandler(.failure(authError))
                return
            }
            completionHandler(.success(()))
        }
    }
}
