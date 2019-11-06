//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Amplify

/// Supported authentication types for the AppSyncClient
public enum AWSAppSyncAuthType: String {
    /// AWS Identity and Access Management (IAM), for role-based authentication
    case awsIAM = "AWS_IAM"

    /// A single API key for all app users
    case apiKey = "API_KEY"

    /// OpenID Connect
    case oidcToken = "OPENID_CONNECT"

    /// User directory based authentication
    case amazonCognitoUserPools = "AMAZON_COGNITO_USER_POOLS"

    /// Convenience method to use instead of `AuthType(rawValue:)`
    public static func getAuthType(rawValue: String) throws -> AWSAppSyncAuthType {
        guard let authType = AWSAppSyncAuthType(rawValue: rawValue) else {
            throw AuthError.unknown("AuthType not recognized. Pass in a valid AuthType.")
        }
        return authType
    }
}
