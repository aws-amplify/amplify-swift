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

//    private var pluginHolder: CategoryPluginHolder {
//        CategoryPluginHolder(categoryType: categoryType)
//    }
//
//    var plugin: DataStoreCategoryPlugin {
//        // swiftlint:disable force_cast
//        pluginHolder.plugin as! DataStoreCategoryPlugin
//        // swiftlint:enable force_cast
//    }
//
//    func add(plugin: DataStoreCategoryPlugin) throws {
//        try pluginHolder.add(plugin: plugin)
//    }

    public func removePlugin(for key: PluginKey) {
//        pluginHolder.removePlugin(for: key)
    }

}
