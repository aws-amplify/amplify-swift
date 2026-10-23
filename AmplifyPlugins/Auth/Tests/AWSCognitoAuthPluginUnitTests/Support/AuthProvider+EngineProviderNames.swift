//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The Cognito provider names moved onto `EngineAuthProvider`. Tests that build a public
/// `AuthProvider` for the plugin API read the name the engine will send through this, so their
/// assertions keep reading `provider.identityPoolProviderName`.
extension AuthProvider {

    var identityPoolProviderName: String {
        EngineAuthProvider(self).identityPoolProviderName
    }
}
