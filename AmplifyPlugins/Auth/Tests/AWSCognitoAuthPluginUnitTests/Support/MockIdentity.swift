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

    typealias GetIdCallback = (
        GetIdInput,
        (SdkResult<GetIdOutputResponse, GetIdOutputError>) -> Void
    ) -> Void

    typealias GetCredentialsCallback = (
        GetCredentialsForIdentityInput,
        (SdkResult<GetCredentialsForIdentityOutputResponse, GetCredentialsForIdentityOutputError>) -> Void
    ) -> Void

    let getIdCallback: GetIdCallback?
    let getCredentialsCallback: GetCredentialsCallback?

    init(getIdCallback: GetIdCallback? = nil,
         getCredentialsCallback: GetCredentialsCallback? = nil)
    {
        self.getIdCallback = getIdCallback
        self.getCredentialsCallback = getCredentialsCallback
    }

    func getId(input: GetIdInput, completion: @escaping (SdkResult<GetIdOutputResponse, GetIdOutputError>) -> Void) {
        getIdCallback?(input, completion)
    }

    func getCredentialsForIdentity(input: GetCredentialsForIdentityInput, completion: @escaping (SdkResult<GetCredentialsForIdentityOutputResponse, GetCredentialsForIdentityOutputError>) -> Void) {
        getCredentialsCallback?(input, completion)
    }

}
