//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AmplifyCredentials: Codable {
    let userPoolTokens: AWSCognitoUserPoolTokens?
    let identityId: String?
    let awsCredential: AuthAWSCognitoCredentials?
}

extension AmplifyCredentials: Equatable { }
