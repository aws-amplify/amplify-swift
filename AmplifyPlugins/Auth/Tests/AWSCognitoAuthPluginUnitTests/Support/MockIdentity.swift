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

    typealias GetIdCallback = (GetIdInput) throws -> GetIdOutputResponse

    typealias GetCredentialsCallback = (GetCredentialsForIdentityInput) throws
    -> GetCredentialsForIdentityOutputResponse

    let getIdCallback: GetIdCallback?
    let getCredentialsCallback: GetCredentialsCallback?

    init(getIdCallback: GetIdCallback? = nil,
         getCredentialsCallback: GetCredentialsCallback? = nil) {
        self.getIdCallback = getIdCallback
        self.getCredentialsCallback = getCredentialsCallback
    }

    func getId(input: GetIdInput) async throws -> GetIdOutputResponse {
        return try getIdCallback!(input)
    }

    func getCredentialsForIdentity(input: GetCredentialsForIdentityInput) async throws -> GetCredentialsForIdentityOutputResponse {
        return try getCredentialsCallback!(input)
    }

}
