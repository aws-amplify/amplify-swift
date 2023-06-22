//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AWSAuthSessionBehavior<TokensType> : AuthSession {
    associatedtype TokensType
    var awsCredentialsResult: Result<AWSTemporaryCredentials, AuthError> { get }
    var identityIdResult: Result<String, AuthError> { get  }
    var userSubResult: Result<String, AuthError> { get }
    var tokensResult: Result<TokensType, AuthError> { get }
}
