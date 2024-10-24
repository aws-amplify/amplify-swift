//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension RESTOperationRequestUtils {

    static func validateApiName(_ apiName: String) throws {
        if apiName.isEmpty {
            throw APIError.unknown("apiName is empty", "provide valid API Name")
        }
    }
}
