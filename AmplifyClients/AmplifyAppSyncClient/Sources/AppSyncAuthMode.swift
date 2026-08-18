//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The authorization modes supported by AWS AppSync.
public enum AppSyncAuthMode: Sendable {
    /// API Key authorization.
    case apiKey
    /// Amazon Cognito User Pools authorization.
    case userPools
    /// OpenID Connect authorization.
    case oidc
    /// AWS IAM authorization (SigV4 signing).
    case iam
    /// AWS Lambda custom authorization.
    case lambda
}
