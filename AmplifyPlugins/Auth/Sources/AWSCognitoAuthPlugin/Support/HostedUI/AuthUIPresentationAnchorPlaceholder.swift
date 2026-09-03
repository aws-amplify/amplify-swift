//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(watchOS) || os(tvOS)

import Foundation

typealias AuthUIPresentationAnchor = AuthUIPresentationAnchorPlaceholder

/// This class serves as a placeholder for the AuthUIPresentationAnchor, which is not available in watchOS.
/// It cannot be initialized and exists strictly to facilitate cross-platform compilation without requiring compiler
/// checks thorughout the codebase.
///
/// - Note: `final` and `Sendable` — a fully checked conformance, not `@unchecked`, since the type has no
///   stored properties and a private `init` so no instance can exist. Without it, `Sendable` inference
///   failed for `HostedUIOptions` on tvOS and watchOS, which then cascaded through `SignInMethod`,
///   `SignedInData` and every state-machine enum carrying them. On the other platforms this typealias
///   resolves to `ASPresentationAnchor` instead, which is why the cascade never appeared on macOS.
final class AuthUIPresentationAnchorPlaceholder: Equatable, Sendable {

    private init() {}

    static func == (
        lhs: AuthUIPresentationAnchorPlaceholder,
        rhs: AuthUIPresentationAnchorPlaceholder
    ) -> Bool {
        true
    }
}

#endif
