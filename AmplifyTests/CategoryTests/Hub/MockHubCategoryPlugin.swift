//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify

class MockHubCategoryPlugin: MessageReporter, HubCategoryPlugin {
    var key: String {
        return "MockHubCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset() {
        notify()
    }

    func dispatch(to channel: HubChannel, payload: HubPayload) {
        notify()
    }

    func listen(to channel: HubChannel,
                filteringWith filter: @escaping HubFilter,
                onEvent: @escaping HubListener) -> UnsubscribeToken {
        notify()
        return UUID()
    }

    func removeListener(_ token: UnsubscribeToken) {
        notify()
    }
}

class MockSecondHubCategoryPlugin: MockHubCategoryPlugin {
    override var key: String {
        return "MockSecondHubCategoryPlugin"
    }
}

final class MockHubCategoryPluginSelector: MessageReporter, HubPluginSelector {
    var selectedPluginKey: PluginKey? = "MockHubCategoryPlugin"

    func dispatch(to channel: HubChannel, payload: HubPayload) {
        notify()
    }

    func listen(to channel: HubChannel,
                filteringWith filter: @escaping HubFilter,
                onEvent: @escaping HubListener) -> UnsubscribeToken {
        notify()
        return UUID()
    }

    func removeListener(_ token: UnsubscribeToken) {
        notify()
    }
}

class MockHubPluginSelectorFactory: MessageReporter, PluginSelectorFactory {
    var categoryType = CategoryType.hub

    func makeSelector() -> PluginSelector {
        notify()
        return MockHubCategoryPluginSelector()
    }

    func add(plugin: Plugin) {
        notify()
    }

    func removePlugin(for key: PluginKey) {
        notify()
    }

}
