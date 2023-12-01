//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@testable import AWSPluginsCore
@testable import AWSCognitoAuthPlugin

class MockAuthPasswordlessBehavior: AuthPasswordlessBehavior {
    
    func preInitiateAuthSignUp(
        endpoint: URL,
        payload: PreInitiateAuthSignUpPayload)
    async -> Result<Void, AuthError> {
        return .successfulVoid
    }
}
