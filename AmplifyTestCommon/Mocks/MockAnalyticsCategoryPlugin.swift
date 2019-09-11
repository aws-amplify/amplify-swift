//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MockAnalyticsCategoryPlugin: MessageReporter, AnalyticsCategoryPlugin {
    var key: String {
        return "MockAnalyticsCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset(onComplete: @escaping (() -> Void)) {
        notify("reset")
        onComplete()
    }

    func disable() {
        notify()
    }

    func enable() {
        notify()
    }

    func record(_ type: String) {
        notify("record(\(type))")
    }

    func record(_ event: AnalyticsEvent) {
        notify("record(event:\(event.name))")
    }

    func update(analyticsProfile: AnalyticsProfile) {
        notify()
    }
}

class MockSecondAnalyticsCategoryPlugin: MockAnalyticsCategoryPlugin {
    override var key: String {
        return "MockSecondAnalyticsCategoryPlugin"
    }
}

final class MockAnalyticsCategoryPluginSelector: MessageReporter, AnalyticsPluginSelector {
    var selectedPluginKey: PluginKey? = "MockAnalyticsCategoryPlugin"

    func disable() {
        notify()
    }

    func enable() {
        notify()
    }

    func record(_ name: String) {
        notify()
    }

    func record(_ event: AnalyticsEvent) {
        notify()
    }

    func update(analyticsProfile: AnalyticsProfile) {
        notify()
    }
}

class MockAnalyticsPluginSelectorFactory: MessageReporter, PluginSelectorFactory {
    var categoryType = CategoryType.analytics

    func makeSelector() -> PluginSelector {
        notify()
        return MockAnalyticsCategoryPluginSelector()
    }

    func add(plugin: Plugin) {
        notify()
    }

    func removePlugin(for key: PluginKey) {
        notify()
    }

}
