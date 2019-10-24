//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore
import Amplify

protocol AWSAuthServiceBehavior {

    func reset()

    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider

    func getIdentityId() -> Result<String, AuthError>
}
