//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthAWSTemporaryCredentials: AuthAWSCredentials {

    var sessionKey: String { get }

    var expiration: Date { get }
}

public protocol AuthAWSCredentials {

    var accessKey: String { get }

    var secretKey: String { get }
}

public struct AuthAWSCognitoCredentials: AuthAWSTemporaryCredentials {

    public let  accessKey: String

    public let  secretKey: String

    public let  sessionKey: String

    public let  expiration: Date
}
