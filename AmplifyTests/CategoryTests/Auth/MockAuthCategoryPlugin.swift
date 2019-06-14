//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MockAuthCategoryPlugin: MessageReporter, AuthCategoryPlugin {
    var key: String {
        return "MockAuthCategoryPlugin"
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

class MockSecondAuthCategoryPlugin: MockAuthCategoryPlugin {
    override var key: String {
        return "MockSecondAuthCategoryPlugin"
    }
}

final class MockAuthCategoryPluginSelector: MessageReporter, AuthPluginSelector {
    var selectedPluginKey: PluginKey? = "MockAuthCategoryPlugin"

    func stub() {
        notify()
    }
}

class MockAuthPluginSelectorFactory: MessageReporter, PluginSelectorFactory {
    var categoryType = CategoryType.auth

    func makeSelector() -> PluginSelector {
        notify()
        return MockAuthCategoryPluginSelector()
    }

    func add(plugin: Plugin) {
        notify()
    }

    func removePlugin(for key: PluginKey) {
        notify()
    }

}
