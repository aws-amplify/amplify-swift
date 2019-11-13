//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension GraphQLOperationRequest {
    // Performs client side validation and returns a `APIError` for any validation failures
    func validate() -> APIError? {
        if let error = GraphQLOperationRequestUtils.validateDocument(document) {
            return error
        }

        if let error = GraphQLOperationRequestUtils.validateVariables(variables) {
            return error
        }

        return nil
    }
}
