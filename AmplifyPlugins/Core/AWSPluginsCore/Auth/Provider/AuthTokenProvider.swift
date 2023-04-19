//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AuthTokenProvider {

    func getToken() -> Result<String, AuthError>

    func getToken(completion: @escaping (Result<String, AuthError>) -> Void)
}

public extension AuthTokenProvider {

    func getToken(completion: @escaping (Result<String, AuthError>) -> Void) {
        let result = getToken()
        completion(result)
    }
}

public struct BasicUserPoolTokenProvider: AuthTokenProvider {

    let authService: AWSAuthServiceBehavior

    public init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    public func getToken() -> Result<String, AuthError> {
        return authService.getToken()
    }

    public func getToken(completion: @escaping (Result<String, AuthError>) -> Void) {
        authService.getUserPoolAccessToken(completion: completion)
    }
}
