//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import ClientRuntime
@testable import AWSCognitoAuthPlugin

struct MockIdentity: CognitoIdentityBehavior {

    typealias MockGetIdResponse = @Sendable (GetIdInput) async throws -> GetIdOutput

    typealias MockGetCredentialsResponse = @Sendable (GetCredentialsForIdentityInput) async throws
    -> GetCredentialsForIdentityOutput

    let mockGetIdResponse: MockGetIdResponse?
    let mockGetCredentialsResponse: MockGetCredentialsResponse?

    init(
        mockGetIdResponse: MockGetIdResponse? = nil,
        mockGetCredentialsResponse: MockGetCredentialsResponse? = nil
    ) {
        self.mockGetIdResponse = mockGetIdResponse
        self.mockGetCredentialsResponse = mockGetCredentialsResponse
    }

    func getId(input: GetIdInput) async throws -> GetIdOutput {
        return try await mockGetIdResponse!(input)
    }

    func getCredentialsForIdentity(input: GetCredentialsForIdentityInput) async throws -> GetCredentialsForIdentityOutput {
        return try await mockGetCredentialsResponse!(input)
    }

}
