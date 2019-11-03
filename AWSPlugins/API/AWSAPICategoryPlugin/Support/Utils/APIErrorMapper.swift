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
        case .dataCorrupted(let context):
            let errorMessage = "dataCorrupted"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError

        case .typeMismatch(let type, let context):
            let errorMessage = "typeMisMatch type: \(type)"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError

        case .valueNotFound(let type, let context):
            let errorMessage = "valueNotFound"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError
        case .keyNotFound(let key, let context):
            let errorMessage = "keyNotFound key \(key)"
            let apiError = GraphQLError.operationError(errorMessage, "", error)
            return apiError
        @unknown default:
            print("failed to decode \(error)")
            let apiError = GraphQLError.operationError("", "", error)
            return apiError
        }
    }
}
