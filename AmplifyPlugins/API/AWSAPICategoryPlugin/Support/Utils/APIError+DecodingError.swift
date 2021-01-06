//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// TODO: Extract context and fill out better error handling

extension APIError {
    init(error: DecodingError) {
        switch error {
        case .dataCorrupted:
            let errorMessage = "dataCorrupted"
            self = .operationError(errorMessage, "", error)
        case .typeMismatch(let type, _):
            let errorMessage = "typeMisMatch type: \(type)"
            self = APIError.operationError(errorMessage, "", error)
        case .valueNotFound:
            let errorMessage = "valueNotFound"
            self = APIError.operationError(errorMessage, "", error)
        case .keyNotFound(let key, _):
            let errorMessage = "keyNotFound key \(key)"
            self = APIError.operationError(errorMessage, "", error)
        @unknown default:
            self = APIError.operationError("Failed to decode", "", error)
        }
    }
}
