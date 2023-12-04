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

struct MockAuthPasswordlessBehavior: AuthPasswordlessBehavior {
    
    typealias MockGetAuthPasswordlessResponse = (URL, PreInitiateAuthSignUpPayload) async throws -> Void
    
    let mockGetAuthPasswordlessResponse: MockGetAuthPasswordlessResponse?
    
    func preInitiateAuthSignUp(
        endpoint: URL,
        payload: PreInitiateAuthSignUpPayload)
    async throws {
        return try await mockGetAuthPasswordlessResponse!(endpoint, payload)
    }
}
