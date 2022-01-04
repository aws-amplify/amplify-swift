//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// TODO: Fix this to user enums or session object
struct AWSCognitoAuthCredential: Codable {
    public let userPoolTokens: AWSCognitoUserPoolTokens?
    public let identityId: String?
    public let awsCredential: AuthAWSCognitoCredentials?
}
