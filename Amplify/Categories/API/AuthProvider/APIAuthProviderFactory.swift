//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
open class APIAuthProviderFactory {

    /// <#Description#>
    public init() {
    }

    /// <#Description#>
    /// - Returns: <#description#>
    open func oidcAuthProvider() -> AmplifyOIDCAuthProvider? {
        return nil
    }
}

/// <#Description#>
public protocol AmplifyOIDCAuthProvider {

    /// <#Description#>
    func getLatestAuthToken() -> Result<String, Error>
}
