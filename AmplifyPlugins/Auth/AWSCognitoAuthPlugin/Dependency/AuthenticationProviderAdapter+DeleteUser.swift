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
        awsMobileClient.deleteUser { error in
            guard let error = error else {
                completionHandler(.success(()))
                return
            }

            //TODO: Handle error
            assertionFailure(error.localizedDescription)
        }
    }
}
