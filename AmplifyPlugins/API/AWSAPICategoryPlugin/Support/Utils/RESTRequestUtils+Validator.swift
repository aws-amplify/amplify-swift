//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension RESTRequestUtils {

    static func validateApiName(_ apiName: String) -> APIError? {
        if apiName.isEmpty {
            return APIError.unknown("apiName is empty", "provide valid API Name")
        }
        return nil
    }
}
