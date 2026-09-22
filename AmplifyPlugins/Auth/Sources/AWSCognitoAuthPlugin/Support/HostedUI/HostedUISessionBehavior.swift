//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AuthenticationServices
import Foundation

/// - Note: `Sendable` for the same reason as `RandomStringBehavior`: the session is produced by a
///   `@Sendable` factory on the HostedUI environment.
protocol HostedUISessionBehavior: Sendable {

    func showHostedUI(
        url: URL,
        callbackScheme: String,
        inPrivate: Bool,
        presentationAnchor: AuthUIPresentationAnchor?
    ) async throws -> [URLQueryItem]
}
