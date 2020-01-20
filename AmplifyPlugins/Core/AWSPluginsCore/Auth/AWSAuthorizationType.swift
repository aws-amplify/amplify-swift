//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// swiftlint:disable line_length

/// The types of authorization one can use while talking to an Amazon AppSync
/// GraphQL backend, or an Amazon API Gateway endpoint.
///
/// - SeeAlso: [https://docs.aws.amazon.com/appsync/latest/devguide/security.html](AppSync Security)
public enum AWSAuthorizationType: String {

    /// For public APIs
    case none = "NONE"

     /// A hardcoded key which can provide throttling for an unauthenticated API.
    /// - SeeAlso: [https://docs.aws.amazon.com/appsync/latest/devguide/security.html#api-key-authorization](API Key Authorization)
    case apiKey = "API_KEY"

     /// Use an IAM access/secret key credential pair to authorize access to an API.
    /// - SeeAlso: [https://docs.aws.amazon.com/appsync/latest/devguide/security.html#aws-iam-authorization](IAM Authorization)
    /// - SeeAlso: [https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html](IAM Introduction)
    case awsIAM = "AWS_IAM"

     /// OpenID Connect is a simple identity layer on top of OAuth2.0.
    /// - SeeAlso: [https://docs.aws.amazon.com/appsync/latest/devguide/security.html#openid-connect-authorization](OpenID Connect Authorization)
    /// - SeeAlso: [https://openid.net/specs/openid-connect-core-1_0.html](OpenID Connect Specification)
    case openIDConnect = "OPENID_CONNECT"

     /// Control access to date by putting users into different permissions pools.
    /// - SeeAlso: [https://docs.aws.amazon.com/appsync/latest/devguide/security.html#amazon-cognito-user-pools-authorization](Amazon Cognito User Pools)
    case amazonCognitoUserPools = "AMAZON_COGNITO_USER_POOLS"

}

// swiftlint:enable line_length

extension AWSAuthorizationType: CaseIterable { }
