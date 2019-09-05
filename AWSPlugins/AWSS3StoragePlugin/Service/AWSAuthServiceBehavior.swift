//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

protocol AWSAuthServiceBehavior {
    func configure()

    func reset()

    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider

    func getIdentityId() -> Result<String, Error>
}
