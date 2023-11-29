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
    
    public var preInitiateAuthSignUpCallCount = 0
    
    func preInitiateAuthSignUp(
        preInitiateAuthSignUpEndpoint: URL,
        preInitiateAuthSignUpPayload: PreInitiateAuthSignUpPayload)
    async throws -> Result<Void, AuthError> {
        preInitiateAuthSignUpCallCount += 1
        return .successfulVoid
    }
}
