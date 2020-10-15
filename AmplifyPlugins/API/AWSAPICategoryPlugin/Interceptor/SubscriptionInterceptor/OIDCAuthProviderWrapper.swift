//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore
import AppSyncRealTimeClient

class OIDCAuthProviderWrapper: AppSyncRealTimeClient.OIDCAuthProvider {

    let oidcAuthProvider: AWSPluginsCore.OIDCAuthProvider

    public init(oidcAuthProvider: AWSPluginsCore.OIDCAuthProvider) {
        self.oidcAuthProvider = oidcAuthProvider
    }

    func getLatestAuthToken() -> Result<String, Error> {
        return oidcAuthProvider.getLatestAuthToken()
    }
}
