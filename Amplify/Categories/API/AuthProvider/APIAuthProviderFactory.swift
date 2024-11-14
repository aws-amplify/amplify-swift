//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// API Auth Provider Factory
open class APIAuthProviderFactory {

    /// Empty public initializer
    public init() {
    }
    
    /// Retrieve the UserPools auth provider
    open func userPoolsAuthProvider() -> AmplifyUserPoolsAuthProvider? {
        return nil
    }
    
    /// Retrieve the OIDC auth provider
    open func oidcAuthProvider() -> AmplifyOIDCAuthProvider? {
        return nil
    }

    open func functionAuthProvider() -> AmplifyFunctionAuthProvider? {
        return nil
    }
}

public protocol AmplifyAuthTokenProvider {
    typealias AuthToken = String

    func getLatestAuthToken() async throws -> String
}

/// Amplify CognitoUserPools Auth Provider
public protocol AmplifyUserPoolsAuthProvider: AmplifyAuthTokenProvider {}

/// Amplify OIDC Auth Provider
public protocol AmplifyOIDCAuthProvider: AmplifyAuthTokenProvider {}

/// Amplify Function Auth Provider
public protocol AmplifyFunctionAuthProvider: AmplifyAuthTokenProvider {}
