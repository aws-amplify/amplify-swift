//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AuthTokenProvider {
    func getLatestAuthToken() async throws -> String
}

public struct BasicUserPoolTokenProvider: AuthTokenProvider {

    let authService: AWSAuthServiceBehavior

    public init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }
    
    public func getLatestAuthToken() async throws -> String {
        try await authService.getLatestAuthToken()
    }
}
