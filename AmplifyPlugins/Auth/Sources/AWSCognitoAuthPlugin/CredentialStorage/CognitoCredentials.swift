//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct CognitoCredentials: Codable {
    public let userPoolTokens: AWSCognitoUserPoolTokens?
    public let identityId: String?
    public let awsCredential: AuthAWSCognitoCredentials?
}

extension CognitoCredentials: Equatable { }
