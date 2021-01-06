//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public protocol AuthAWSCredentialsProvider {
    func getAWSCredentials() -> Result<AuthAWSCredentials, AuthError>
}

public protocol AuthAWSTemporaryCredentials: AuthAWSCredentials {

    var sessionKey: String { get }

    var expiration: Date { get }
}

public protocol AuthAWSCredentials {

    var accessKey: String { get }

    var secretKey: String { get }
}
