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

    /// Consolidates unauthorized error scenarios coming from `APIError.httpStatusError` and `APIError.operationError`.
    /// For `.httpStatusError`, this checks if the status code is 403. For `.operationError`, this checks if the error
    /// description contains "Unauthorized".
    ///
    /// **Warning** Customized server responses that indicate unauthorized may not match the internal mapping done
    /// in this API and return `false`. Check APIError enum cases directly.
    ///
    /// - Returns: `true` if unauthorized error, `false` otherwise
    public func isUnauthorized() -> Bool {
        if case .operationError(let errorDescription, _, _) = self,
           errorDescription.range(of: APIError.UnauthorizedMessageString, options: .caseInsensitive) != nil {
            return true
        } else if case .httpStatusError(let statusCode, _) = self, statusCode == 403 {
            return true
        }

        return false
    }
}
