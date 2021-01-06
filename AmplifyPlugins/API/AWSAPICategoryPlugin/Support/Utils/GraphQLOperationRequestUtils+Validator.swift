//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension GraphQLOperationRequestUtils {

    static func validateDocument(_ document: String) throws {
        if document.isEmpty {
            throw APIError.unknown("document is empty", "provide a valid document")
        }
    }

    static func validateVariables(_ variables: [String: Any]?) throws {
        if let variables = variables {

            if !JSONSerialization.isValidJSONObject(variables) {
                throw APIError.operationError("Variables is a not a valid JSON object", "")
            }
        }
    }
}
