//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Represents authentication tokens (e.g., Cognito user-pool tokens).
public protocol AuthToken {
    /// The ID token (contains user claims).
    var idToken: String { get }

    /// The access token (used for API authorization).
    var accessToken: String { get }

    /// The refresh token (used to obtain new access/ID tokens).
    var refreshToken: String { get }
}
