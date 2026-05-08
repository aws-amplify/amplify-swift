//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Wraps the authorizer(s) that the client uses.
///
/// Supports both single-auth (one authorizer for all requests) and multi-auth
/// (multiple authorizers, selected based on model `@auth` rules or per-request overrides).
public enum AppSyncAuthorization: Sendable {

    /// Single authorizer used for all requests.
    case single(AppSyncAuthorizer)

    /// Multiple authorizers. The client selects the appropriate one based on model
    /// `@auth` rules or per-request auth mode overrides. Falls back to `defaultAuthMode`
    /// when no rule matches.
    ///
    /// - Parameters:
    ///   - defaultAuthMode: The auth mode to use when no per-request override or model rule applies.
    ///   - authorizers: The list of authorizers. Duplicate auth modes are not allowed.
    case multi(defaultAuthMode: AppSyncAuthMode, authorizers: [AppSyncAuthorizer])
}

extension AppSyncAuthorization {

    /// Resolves the authorizer for a given auth mode.
    /// - Returns: The matching authorizer, or nil if not found.
    func authorizer(for mode: AppSyncAuthMode) -> AppSyncAuthorizer? {
        switch self {
        case .single(let authorizer):
            return authorizer.authMode == mode ? authorizer : nil
        case .multi(_, let authorizers):
            return authorizers.first { $0.authMode == mode }
        }
    }

    /// The default authorizer.
    var defaultAuthorizer: AppSyncAuthorizer {
        switch self {
        case .single(let authorizer):
            return authorizer
        case .multi(let defaultAuthMode, let authorizers):
            guard let authorizer = authorizers.first(where: { $0.authMode == defaultAuthMode }) else {
                preconditionFailure(
                    "No authorizer provided for the default auth mode: \(defaultAuthMode). " +
                    "Ensure the authorizers list contains an entry matching the defaultAuthMode."
                )
            }
            return authorizer
        }
    }

    /// The default auth mode.
    var defaultAuthMode: AppSyncAuthMode {
        switch self {
        case .single(let authorizer):
            return authorizer.authMode
        case .multi(let defaultAuthMode, _):
            return defaultAuthMode
        }
    }
}
