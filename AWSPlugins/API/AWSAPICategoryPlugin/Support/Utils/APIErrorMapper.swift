//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class APIErrorMapper {
    static func handleDecodingError(error: DecodingError) -> GraphQLError {
        switch error {
        case .dataCorrupted(_):
            let errorMessage = "dataCorrupted"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError

        case .typeMismatch(let type, _):
            let errorMessage = "typeMisMatch type: \(type)"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError

        case .valueNotFound(let type, _):
            let errorMessage = "valueNotFound"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError
        case .keyNotFound(let key, _):
            let errorMessage = "keyNotFound key \(key)"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError
        @unknown default:
            let apiError = GraphQLError.operationError("Failed to decode", "", error)
            return apiError
        }
    }
}
