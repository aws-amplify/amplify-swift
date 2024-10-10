//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

extension KeychainStoreError: AuthErrorConvertible {

    var authError: AuthError {
        switch self {
        case .configuration(let message):
            return .configuration(message, recoverySuggestion)
        case .unknown(let errorDescription, let error):
            return .unknown(errorDescription, error)
        case .conversionError(let errorDescription, let error):
            return .configuration(errorDescription, recoverySuggestion, error)
        case .codingError(let errorDescription, let error):
            return .configuration(errorDescription, recoverySuggestion, error)
        case .itemNotFound:
            return .service(errorDescription, recoverySuggestion)
        case .securityError:
            return .service(errorDescription, recoverySuggestion)
        }
    }
}
