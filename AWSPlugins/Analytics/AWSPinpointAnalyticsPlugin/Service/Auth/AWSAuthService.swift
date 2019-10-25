//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient

// TODO: This class should be refactored into common module -  https://github.com/aws-amplify/amplify-ios/issues/21
protocol AWSAuthServiceBehavior {
    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider
}
class AWSAuthService: AWSAuthServiceBehavior {
    var mobileClient: AWSMobileClientBehavior!

    init(mobileClient: AWSMobileClientBehavior? = nil) {
        let mobileClient = mobileClient ?? AWSMobileClientAdapter(AWSMobileClient.default())
        self.mobileClient = mobileClient
    }

    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        return mobileClient.getCognitoCredentialsProvider()
    }
    func reset() {
        mobileClient = nil
    }
}
protocol AWSMobileClientBehavior {
    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider
}

class AWSMobileClientAdapter: AWSMobileClientBehavior {
    let awsMobileClient: AWSMobileClient

    init(_ awsMobileClient: AWSMobileClient) {
        self.awsMobileClient = awsMobileClient
    }

    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        return awsMobileClient
    }
}
