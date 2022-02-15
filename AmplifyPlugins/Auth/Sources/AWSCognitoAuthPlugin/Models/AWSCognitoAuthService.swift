//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider

public enum AWSCognitoAuthService {

    /// Only AWS Cognito User Pool auth service is configured. The associated value contains the
    /// underlying low level client
    case userPool(CognitoIdentityProviderClient)

    /// Only AWS Cognito Identity Pool auth service is configured. The associated value contains the
    /// underlying low level client
    case identityPool(CognitoIdentityClient)

    /// Both AWS Cognito User Pool and AWS Identity Pool  auth services are configured. The associated
    /// value contains the underlying low level clients.
    case userPoolAndIdentityPool(CognitoIdentityProviderClient,
                                 CognitoIdentityClient)
}
