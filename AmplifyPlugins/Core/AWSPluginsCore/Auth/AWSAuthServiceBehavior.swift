//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCore
import Amplify

public protocol AWSAuthServiceBehavior: class {
    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider

    func getIdentityId() -> Result<String, AuthError>

    func getToken() -> Result<String, AuthError>

    func reset()

}
