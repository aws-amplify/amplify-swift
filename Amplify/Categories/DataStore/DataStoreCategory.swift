//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

final public class DataStoreCategory: Category {

    /// Always .dataStore
    public let categoryType: CategoryType = .dataStore

    public func removePlugin(for key: PluginKey) {
        // TODO implement this
    }
}
