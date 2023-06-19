//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public protocol AWSAuthSessionBehavior<OIDCCredentials> : AuthSession {
    associatedtype OIDCCredentials
    var awsCredentialsResult: Result<AWSTemporaryCredentials, AuthError> { get }
    var identityIdResult: Result<String, AuthError> { get  }
    var userSubResult: Result<String, AuthError> { get }
    var oidcTokensResult: Result<OIDCCredentials, AuthError> { get }
}
