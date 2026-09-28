//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AuthenticationServices
import Foundation

/// - Note: `Sendable` for the same reason as `RandomStringBehavior`: the session is produced by a
///   `@Sendable` factory on the HostedUI environment.
package protocol HostedUISessionBehavior: Sendable {

    func showHostedUI(
        url: URL,
        callbackScheme: String,
        inPrivate: Bool,
        presentationAnchor: EnginePresentationAnchor?
    ) async throws -> [URLQueryItem]

    /// Dismisses the browser this presenter is showing and ends its `showHostedUI` with
    /// `HostedUIError.cancelled`. Must return promptly: it runs from cancellation handlers. Idempotent.
    ///
    /// The default does nothing, for a presenter that cannot be cancelled (the plugin's test doubles).
    func cancel()
}

package extension HostedUISessionBehavior {

    func cancel() {}
}
