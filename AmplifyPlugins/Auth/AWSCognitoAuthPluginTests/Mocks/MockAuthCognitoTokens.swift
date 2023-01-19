//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

struct MockAuthCognitoTokens: AuthCognitoTokens {
    var idToken: String = UUID().uuidString
    var accessToken: String = UUID().uuidString
    var refreshToken: String = UUID().uuidString
}
