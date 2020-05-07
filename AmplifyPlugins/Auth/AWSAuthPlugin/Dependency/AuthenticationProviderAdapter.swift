//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

class AuthenticationProviderAdapter: AuthenticationProviderBehavior {

    let awsMobileClient: AWSMobileClientBehavior

    init(awsMobileClient: AWSMobileClientBehavior) {
        self.awsMobileClient = awsMobileClient
    }

    func signInUsername() -> Result<String, AmplifyAuthError> {

        if let username = awsMobileClient.username() {
            return .success(username)
        }
        // TODO: Fix the error here
        return .failure(AmplifyAuthError.unknown(""))

    }
}
