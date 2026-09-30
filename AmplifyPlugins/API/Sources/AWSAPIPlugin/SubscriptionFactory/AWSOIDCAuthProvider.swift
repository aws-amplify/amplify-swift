//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Foundation

/// - Note: `final` and `Sendable` so `getLatestAuthToken` can be passed as a `@Sendable` closure
///   to `AuthTokenInterceptor`.
final class AWSOIDCAuthProvider: Sendable {

    let authService: AWSAuthServiceBehavior

    init(authService: AWSAuthServiceBehavior) {
        self.authService = authService
    }

    func getLatestAuthToken() async throws -> String {
        try await authService.getUserPoolAccessToken()
    }
}
