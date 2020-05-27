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

    func getCurrentUser() -> AuthUser? {

        guard let username = awsMobileClient.getUsername() else {
            return nil
        }
        guard let sub = awsMobileClient.getUserSub() else {
            return nil
        }
        return  AWSAuthUser(username: username, userId: sub)
    }
}
