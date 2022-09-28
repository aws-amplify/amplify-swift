//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public protocol AuthAWSCredentialsProvider {
    func getAWSCredentials() -> Result<AWSCredentials, AuthError>
}

public protocol AWSTemporaryCredentials: AWSCredentials {

    var sessionKey: String { get }

    var expiration: Date { get }
}

public protocol AWSCredentials {

    var accessKey: String { get }

    var secretKey: String { get }
}
