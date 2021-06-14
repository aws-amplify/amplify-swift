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

    /// Retrieve the OIDC auth provider
    open func oidcAuthProvider() -> AmplifyOIDCAuthProvider? {
        return nil
    }
}

/// Amplify OIDC Auth Provider
public protocol AmplifyOIDCAuthProvider {

    /// Retrieve the latest auth token
    func getLatestAuthToken() -> Result<String, Error>
}
