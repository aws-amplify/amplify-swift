//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct AWSCognitoUserPoolTokens: AuthCognitoTokens {

    public let idToken: String

    public let accessToken: String

    public let refreshToken: String

}

struct AuthAWSCognitoCredentials: AuthAWSTemporaryCredentials {

    public let  accessKey: String

    public let  secretKey: String

    public let  sessionKey: String

    public let  expiration: Date
}
