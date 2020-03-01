//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

    public func getLatestAuthToken(_ callback: @escaping (String?, Error?) -> Void) {
        let result = authService.getToken()
        switch result {
        case .success(let token):
            callback(token, nil)
        case .failure(let error):
            callback(nil, error)
        }
    }
}
