//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

open class APIAuthProviderFactory {
    public init() {
    }
    open func oidcAuthProvider() -> AmplifyOIDCAuthProvider? {
        return nil
    }
}

public protocol AmplifyOIDCAuthProvider {
    func getLatestAuthToken() -> Result<String, Error>
}
