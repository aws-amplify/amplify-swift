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

class AuthenticationProviderAdapter: AuthenticationProviderBehavior {

    let awsMobileClient: AWSMobileClientBehavior

    let userdefaults: AWSCognitoAuthPluginUserDefaultsBehavior

    init(awsMobileClient: AWSMobileClientBehavior,
         userdefaults: AWSCognitoAuthPluginUserDefaultsBehavior = AWSCognitoAuthPluginUserDefaults()) {
        self.awsMobileClient = awsMobileClient
        self.userdefaults = userdefaults
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
