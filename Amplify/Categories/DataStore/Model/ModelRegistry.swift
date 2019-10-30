//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

var modelTypeCache: [String: Model.Type] = [:]

public func modelType(from name: String) -> Model.Type? {
    return modelTypeCache[name]
}

public func registerModel(type: Model.Type) {
    let name = String(describing: type)
    modelTypeCache[name] = type
}
