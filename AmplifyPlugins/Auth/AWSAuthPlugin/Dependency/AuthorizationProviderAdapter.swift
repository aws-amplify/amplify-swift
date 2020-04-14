//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class AuthorizationProviderAdapter: AuthorizationProviderBehavior {

    let awsmobileClient: AWSMobileClientBehavior

    init(awsmobileClient: AWSMobileClientBehavior) {
        self.awsmobileClient = awsmobileClient
    }

    func fetchSession() {
        //TODO: Complete implementation
    }
}
