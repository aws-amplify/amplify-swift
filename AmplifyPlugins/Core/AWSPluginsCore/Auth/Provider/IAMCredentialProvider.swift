//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import Amplify

public protocol IAMCredentialsProvider {
    // TODO: Should we really be returning `AWSCognitoCredentialsProvider`?
    func getCredentialsProvider() -> AWSCognitoCredentialsProvider
}

public struct BasicIAMCredentialsProvider: IAMCredentialsProvider {
    let authService: AWSAuthServiceBehavior

    public init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    public func getCredentialsProvider() -> AWSCognitoCredentialsProvider {
        return authService.getCognitoCredentialsProvider()
    }
}
