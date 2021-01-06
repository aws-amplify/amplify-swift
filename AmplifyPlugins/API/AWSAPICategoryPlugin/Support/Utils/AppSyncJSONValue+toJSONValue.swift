//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AppSyncRealTimeClient

extension AppSyncJSONValue {
    static func toJSONValue(_ json: AppSyncJSONValue) -> JSONValue {
        switch json {
        case .array(let values):
            return JSONValue.array(values.map(AppSyncJSONValue.toJSONValue))
        case .boolean(let value):
            return JSONValue.boolean(value)
        case .null:
            return JSONValue.null
        case .number(let value):
            return JSONValue.number(value)
        case .object(let content):
            return JSONValue.object(content.reduce(into: [:]) { acc, partial in
                let (key, value) = partial
                acc[key] = AppSyncJSONValue.toJSONValue(value)
            })
        case .string(let value):
            return JSONValue.string(value)
        }
    }
}
