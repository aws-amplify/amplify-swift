//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AuthTokenProvider {
    @available(*, deprecated, message: "Use getUserPoolAccessToken(completion:) instead")
    func getToken() -> Result<String, AuthError>
    
    func getUserPoolAccessToken(completion: @escaping (Result<String, AuthError>) -> Void)
}

public struct BasicUserPoolTokenProvider: AuthTokenProvider {

    let authService: AWSAuthServiceBehavior

    public init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    public func getUserPoolAccessToken(completion: @escaping (Result<String, AuthError>) -> Void) {
        authService.getUserPoolAccessToken(completion: completion)
    }
    
    @available(*, deprecated, message: "Use getUserPoolAccessToken(completion:) instead")
    public func getToken() -> Result<String, AuthError> {
        return self.authService.getToken()
    }
}
