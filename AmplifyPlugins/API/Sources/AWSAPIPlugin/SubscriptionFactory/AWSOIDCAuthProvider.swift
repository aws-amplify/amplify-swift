//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

class AWSOIDCAuthProvider {

    var authService: AWSAuthServiceBehavior

    init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    func getLatestAuthToken() async throws -> String {
        try await authService.getUserPoolAccessToken()
    }
}
