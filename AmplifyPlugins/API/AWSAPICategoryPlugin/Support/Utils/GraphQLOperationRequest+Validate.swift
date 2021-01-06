//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension GraphQLOperationRequest {
    // Performs client side validation and returns a `APIError` for any validation failures
    func validate() throws {
        try GraphQLOperationRequestUtils.validateDocument(document)
        try GraphQLOperationRequestUtils.validateVariables(variables)
    }
}
