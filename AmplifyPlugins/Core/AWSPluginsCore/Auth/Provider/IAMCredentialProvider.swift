//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import Amplify

public protocol IAMCredentialsProvider {
    func getCredentialsProvider() -> AWSCredentialsProvider
}

public struct BasicIAMCredentialsProvider: IAMCredentialsProvider {
    let authService: AWSAuthServiceBehavior

    public init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    public func getCredentialsProvider() -> AWSCredentialsProvider {
        return authService.getCredentialsProvider()
    }
}
