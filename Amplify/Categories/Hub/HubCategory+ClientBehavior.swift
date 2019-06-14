//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension HubCategory: HubCategoryClientBehavior {
    private func plugin(from selector: HubPluginSelector) -> HubCategoryPlugin {
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

    public func dispatch(to channel: HubChannel, payload: HubPayload) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.dispatch(to: channel, payload: payload)
        case .selector(let selector):
            selector.dispatch(to: channel, payload: payload)
            plugin(from: selector).dispatch(to: channel, payload: payload)
        }
    }

    public func listen(to channel: HubChannel,
                       filteringWith filter: @escaping HubFilter,
                       onEvent: @escaping HubListener) -> UnsubscribeToken {
        switch pluginOrSelector {
        case .plugin(let plugin):
            return plugin.listen(to: channel, filteringWith: filter, onEvent: onEvent)
        case .selector(let selector):
            _ = selector.listen(to: channel, filteringWith: filter, onEvent: onEvent)
            return plugin(from: selector).listen(to: channel, filteringWith: filter, onEvent: onEvent)
        }
    }

    public func removeListener(_ token: UnsubscribeToken) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.removeListener(token)
        case .selector(let selector):
            selector.removeListener(token)
            plugin(from: selector).removeListener(token)
        }
    }

}
