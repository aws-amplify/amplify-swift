//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AnalyticsCategory: AnalyticsCategoryClientBehavior {
    private func plugin(from selector: AnalyticsPluginSelector) -> AnalyticsCategoryPlugin {
        guard let key = selector.selectedPluginKey else {
            preconditionFailure(
                """
                \(String(describing: selector)) did not set `selectedPluginKey` for the function `\(#function)`
                """)
        }
        guard let plugin = try? getPlugin(for: key) else {
            preconditionFailure(
                """
                \(String(describing: selector)) set `selectedPluginKey` to \(key) for the function `\(#function)`,
                but there is no plugin added for that key.
                """)
        }
        return plugin
    }

    public func disable() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.disable()
        case .selector(let selector):
            selector.disable()
            plugin(from: selector).disable()
        }
    }

    public func enable() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.enable()
        case .selector(let selector):
            selector.enable()
            plugin(from: selector).enable()
        }
    }

    public func record(_ name: String) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.record(name)
        case .selector(let selector):
            selector.record(name)
            plugin(from: selector).record(name)
        }
    }

    public func record(_ event: AnalyticsEvent) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.record(event)
        case .selector(let selector):
            selector.record(event)
            plugin(from: selector).record(event)
        }
    }

    public func update(analyticsProfile: AnalyticsProfile) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.update(analyticsProfile: analyticsProfile)
        case .selector(let selector):
            selector.update(analyticsProfile: analyticsProfile)
            plugin(from: selector).update(analyticsProfile: analyticsProfile)
        }
    }

}
