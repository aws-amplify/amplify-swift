//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore
import AppSyncRealTimeClient

class AWSOIDCAuthProvider: OIDCAuthProvider {

    var authService: AWSAuthServiceBehavior

    init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    func getLatestAuthToken() -> Result<String, Error> {
        switch authService.getToken() {
        case .success(let token):
            return .success(token)
        case .failure(let authError):
            return .failure(authError)
        }
    }
}
