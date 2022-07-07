//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AuthTokenProvider {
    
    func getUserPoolAccessToken(completion: @escaping (Result<String, AuthError>) -> Void)
    
    func getUserPoolAccessToken() async throws -> String
}

public struct BasicUserPoolTokenProvider: AuthTokenProvider {

    let authService: AWSAuthServiceBehavior

    public init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    public func getUserPoolAccessToken(completion: @escaping (Result<String, AuthError>) -> Void) {
        authService.getUserPoolAccessToken(completion: completion)
    }
    
    public func getUserPoolAccessToken() async throws -> String {
        try await authService.getUserPoolAccessToken()
    }
}
