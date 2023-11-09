//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore
import Amplify

extension KeychainStoreError: AuthErrorConvertible {

    var authError: AuthError {
        switch self {
        case .configuration(let message):
            return .configuration(message, self.recoverySuggestion)
        case .unknown(let errorDescription, let error):
            return .unknown(errorDescription, error)
        case .conversionError(let errorDescription, let error):
            return .configuration(errorDescription, self.recoverySuggestion, error)
        case .codingError(let errorDescription, let error):
            return .configuration(errorDescription, self.recoverySuggestion, error)
        case .itemNotFound:
            return .service(self.errorDescription, self.recoverySuggestion)
        case .securityError:
            return .service(self.errorDescription, self.recoverySuggestion)
        }
    }
}
