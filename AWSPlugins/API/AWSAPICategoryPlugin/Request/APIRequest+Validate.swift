//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension APIRequest {
    // Performs client side validation and returns a `APIError` for any validation failures
    func validate() -> APIError? {

        if let error = APIRequestUtils.validateApiName(apiName) {
            return error
        }

        return nil
    }
}
