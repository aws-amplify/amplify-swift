//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient

class AWSMobileClientImpl: AWSMobileClientBehavior {
    let awsMobileClient: AWSMobileClient
    init(_ awsMobileClient: AWSMobileClient) {
        self.awsMobileClient = awsMobileClient
    }

    func getIdentityId() -> AWSTask<NSString> {
        return awsMobileClient.getIdentityId()
    }

    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        return awsMobileClient
    }
}
