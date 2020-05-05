//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

extension AuthenticationProviderAdapter {

    func signOut(request: AuthSignOutRequest,
                 completionHandler: @escaping (Result<Void, AmplifyAuthError>) -> Void) {

        let signOutOptions = SignOutOptions(signOutGlobally: true, invalidateTokens: true)
        awsMobileClient.signOut(options: signOutOptions) { error in
            guard error == nil else {
                let authError = AuthErrorHelper.toAmplifyAuthError(error!)
                completionHandler(.failure(authError))
                return
            }
            completionHandler(.success(()))
        }
    }
}
