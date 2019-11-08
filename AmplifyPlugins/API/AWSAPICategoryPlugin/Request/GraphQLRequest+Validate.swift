//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension GraphQLRequest {
    // Performs client side validation and returns a `APIError` for any validation failures
    func validate() -> APIError? {
        if let error = GraphQLRequestUtils.validateDocument(document) {
            return error
        }

        if let error = GraphQLRequestUtils.validateVariables(variables) {
            return error
        }

        return nil
    }
}

