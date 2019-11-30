//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Array where Element: Model {

    public func unique() throws -> Element? {
        guard (0 ... 1).contains(count) else {
            throw DataStoreError.nonUniqueResult(model: Element.modelName, count: count)
        }
        return first
    }
}

extension Array where Element == Model {
    public func unique() throws -> Element? {
        guard (0 ... 1).contains(count) else {
            let firstModelName = self[0].modelName
            throw DataStoreError.nonUniqueResult(model: firstModelName, count: count)
        }
        return first
    }
}
