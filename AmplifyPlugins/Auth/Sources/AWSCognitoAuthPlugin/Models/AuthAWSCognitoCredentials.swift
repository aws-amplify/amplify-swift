//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

public struct AuthAWSCognitoCredentials: AuthAWSTemporaryCredentials {

    public let  accessKey: String

    public let  secretKey: String

    public let  sessionKey: String

    public let  expiration: Date
}

extension AuthAWSCognitoCredentials: Codable { }

extension AuthAWSCognitoCredentials: Equatable { }
