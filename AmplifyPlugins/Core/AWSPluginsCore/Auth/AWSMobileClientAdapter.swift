//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient
import Amplify

/// The class confirming to AWSMobileClientBehavior which uses an instance of the AWSMobileClient to perform its methods
/// This class acts as a wrapper to expose AWSMobileClient functionality through an instance over a singleton, and
/// allows for mocking in unit tests. The methods contain no other logic other than calling the same method using
/// the AWSMobileClient instance.
class AWSMobileClientAdapter: AWSMobileClientBehavior {
    let awsMobileClient: AWSMobileClient

    init(_ awsMobileClient: AWSMobileClient) {
        self.awsMobileClient = awsMobileClient
    }

    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        return awsMobileClient
    }

    func getIdentityId() -> AWSTask<NSString> {
        return awsMobileClient.getIdentityId()
    }

    func getTokens(completionHandler: @escaping (Tokens?, Error?) -> Void) {
        awsMobileClient.getTokens(completionHandler)
    }
}
