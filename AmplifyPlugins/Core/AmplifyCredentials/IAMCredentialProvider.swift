//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSClientRuntime
import AWSPluginsCore

public protocol IAMCredentialsProvider {
    func getCredentialsProvider() -> CredentialsProviding
}

public struct BasicIAMCredentialsProvider: IAMCredentialsProvider {
    let authService: AWSAuthCredentialsProviderBehavior

    public init(authService: AWSAuthCredentialsProviderBehavior) {
        self.authService = authService
    }

    public func getCredentialsProvider() -> CredentialsProviding {
        return authService.getCredentialsProvider()
    }
}
