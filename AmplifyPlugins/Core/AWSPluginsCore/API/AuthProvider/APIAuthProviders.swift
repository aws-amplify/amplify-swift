//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

public protocol APIAuthProviders {
//    func apiKeyAuthProvider() throws -> APIAuthProviderAPIKey
//    func awsCredentialsProvider() throws -> APIAuthProviderAWSCredentials
//    func cognitoUserPoolsAuthProvider() throws -> APIAuthProviderCognitoUserPools
    func oidcAuthProvider() -> OIDCAuthProvider
}

public protocol OIDCAuthProvider {
    func getLatestAuthToken() -> Result<String, Error>
}
//public protocol APIAuthProviderAPIKey {
//    func apiKey() throws -> String
//}
//
//public protocol APIAuthProviderAWSCredentials {
//    //todo
//}
//public protocol APIAuthProviderCognitoUserPools {
//    func getLatestAuthToken() throws -> String
//}

//public protocol APIAuthProviderOIDC {
//    func getLatestAuthToken() throws -> String
//}
