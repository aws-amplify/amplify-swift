//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import ClientRuntime

public protocol CognitoIdentityBehavior {
    
    /// Generates (or retrieves) a Cognito ID. Supplying multiple logins will create an implicit linked account.
    /// This is a public API. You do not need any credentials to call this API.
    func getId(
        input: GetIdInput,
        completion: @escaping (SdkResult<GetIdOutputResponse, GetIdOutputError>) -> Void)
    
    /// Returns credentials for the provided identity ID.
    /// Any provided logins will be validated against supported login providers. If the token is for cognito-identity.amazonaws.com,
    /// it will be passed through to AWS Security Token Service with the appropriate role for the token.
    /// This is a public API. You do not need any credentials to call this API.
    func getCredentialsForIdentity(
        input: GetCredentialsForIdentityInput,
        completion: @escaping (SdkResult<GetCredentialsForIdentityOutputResponse,
                               GetCredentialsForIdentityOutputError>) -> Void)

}
