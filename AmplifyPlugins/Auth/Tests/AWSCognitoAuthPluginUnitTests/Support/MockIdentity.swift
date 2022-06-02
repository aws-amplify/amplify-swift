//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentity
import ClientRuntime

struct MockIdentity: CognitoIdentityBehavior {

    typealias MockGetIdResponse = (GetIdInput) async throws -> GetIdOutputResponse

    typealias MockGetCredentialsResponse = (GetCredentialsForIdentityInput) async throws
    -> GetCredentialsForIdentityOutputResponse

    let mockGetIdResponse: MockGetIdResponse?
    let mockGetCredentialsResponse: MockGetCredentialsResponse?

    init(mockGetIdResponse: MockGetIdResponse? = nil,
         mockGetCredentialsResponse: MockGetCredentialsResponse? = nil) {
        self.mockGetIdResponse = mockGetIdResponse
        self.mockGetCredentialsResponse = mockGetCredentialsResponse
    }

    func getId(input: GetIdInput) async throws -> GetIdOutputResponse {
        return try await mockGetIdResponse!(input)
    }

    func getCredentialsForIdentity(input: GetCredentialsForIdentityInput) async throws -> GetCredentialsForIdentityOutputResponse {
        return try await mockGetCredentialsResponse!(input)
    }

}
