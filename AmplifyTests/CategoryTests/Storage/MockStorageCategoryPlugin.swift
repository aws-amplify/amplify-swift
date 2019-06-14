//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MockStorageCategoryPlugin: MessageReporter, StorageCategoryPlugin {
    var key: String {
        return "MockStorageCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset() {
        notify()
    }

    func stub() {
        notify()
    }
}

class MockSecondStorageCategoryPlugin: MockStorageCategoryPlugin {
    override var key: String {
        return "MockSecondStorageCategoryPlugin"
    }
}

final class MockStorageCategoryPluginSelector: MessageReporter, StoragePluginSelector {
    var selectedPluginKey: PluginKey? = "MockStorageCategoryPlugin"

    func stub() {
        notify()
    }
}

class MockStoragePluginSelectorFactory: MessageReporter, PluginSelectorFactory {
    var categoryType = CategoryType.storage

    func makeSelector() -> PluginSelector {
        notify()
        return MockStorageCategoryPluginSelector()
    }

    func add(plugin: Plugin) {
        notify()
    }

    func removePlugin(for key: PluginKey) {
        notify()
    }

}
