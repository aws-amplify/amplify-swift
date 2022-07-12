//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AppSyncRealTimeClient

extension APIError {

    static let UnauthorizedMessageString: String = "Unauthorized"

    /// By default, this consolidates unauthorized error scenarios coming from `APIError.httpStatusError` and
    /// `APIError.operationError`. For `.httpStatusError`, this checks if the status code is 401 or 403. For
    /// `.operationError`, this checks if the error description contains "Unauthorized".
    ///
    /// **Warning** Customized server responses that indicate unauthorized may not match the internal mapping done
    /// in this API and return `false`. Check APIError enum directly or create your own `UnauthorizedDeterming` rule,
    /// for example:
    /// ```
    /// static let customRule = UnauthorizedDetermining { error in
    ///     // Your custom logic to determine if `error` is unauthorized.
    ///     // return `true` or `false`.
    /// }
    /// ```
    ///
    /// - Parameter rule: Used to determine if the `APIError` is an unauthorized error.
    /// - Returns: `true` if unauthorized error, `false` otherwise
    public func isUnauthorized(rule: UnauthorizedDetermining = .default) -> Bool {
        rule.isUnauthenticated(self)
    }

    public struct UnauthorizedDetermining {
        let isUnauthenticated: (APIError) -> Bool

        public init(isUnauthenticated: @escaping (APIError) -> Bool) {
            self.isUnauthenticated = isUnauthenticated
        }

        public static let `default` = UnauthorizedDetermining { error in
            error.containsUnauthorizedMessageString || error.is401or403
        }
    }

    private var is401or403: Bool {
        switch self {
        case .httpStatusError(let statusCode, _):
            return statusCode == 401 || statusCode == 403
        default:
            return false
        }
    }

    private var containsUnauthorizedMessageString: Bool {
        switch self {
        case .operationError(let errorDescription, _, _):
            return errorDescription.range(of: APIError.UnauthorizedMessageString, options: .caseInsensitive) != nil
        default: return false
        }
    }
}
