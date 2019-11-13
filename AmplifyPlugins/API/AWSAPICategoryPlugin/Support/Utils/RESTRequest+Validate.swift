//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension RESTRequest {
    // Performs client side validation and returns a `APIError` for any validation failures
    func validate() -> APIError? {

        if let error = RESTRequestUtils.validateApiName(apiName) {
            return error
        }

        return nil
    }
}
