//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AppSyncRealTimeClient

class OIDCAuthProviderWrapper: OIDCAuthProvider {

    let oidcAuthProvider: AmplifyOIDCAuthProvider

    public init(oidcAuthProvider: AmplifyOIDCAuthProvider) {
        self.oidcAuthProvider = oidcAuthProvider
    }

    func getLatestAuthToken() -> Result<String, Error> {
        return oidcAuthProvider.getLatestAuthToken()
    }
}
