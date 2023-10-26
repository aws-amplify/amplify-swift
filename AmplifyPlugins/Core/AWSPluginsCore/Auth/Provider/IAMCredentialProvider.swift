//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
//import AWSClientRuntime

public protocol IAMCredentialsProvider {
    func _credentialsProvider() -> CredentialsProvider
}

public struct BasicIAMCredentialsProvider: IAMCredentialsProvider {
    let authService: AWSAuthServiceBehavior

    public init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    public func _credentialsProvider() -> CredentialsProvider {
        return authService._credentialsProvider()
    }
}
