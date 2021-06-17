//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCore
import Amplify

public protocol AWSAuthServiceBehavior: AnyObject {

    func getCredentialsProvider() -> AWSCredentialsProvider

    func getIdentityId() -> Result<String, AuthError>

    func getToken() -> Result<String, AuthError>

    func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError>
}
