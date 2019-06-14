//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryClientBehavior {
    private func plugin(from selector: APIPluginSelector) -> APICategoryPlugin {
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

    public func delete() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.delete()
        case .selector(let selector):
            selector.delete()
            plugin(from: selector).delete()
        }
    }

    public func get() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.get()
        case .selector(let selector):
            selector.get()
            plugin(from: selector).get()
        }
    }

    public func head() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.head()
        case .selector(let selector):
            selector.head()
            plugin(from: selector).head()
        }
    }

    public func options() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.options()
        case .selector(let selector):
            selector.options()
            plugin(from: selector).options()
        }
    }

    public func patch() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.patch()
        case .selector(let selector):
            selector.patch()
            plugin(from: selector).patch()
        }
    }

    public func post() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.post()
        case .selector(let selector):
            selector.post()
            plugin(from: selector).post()
        }
    }

    public func put() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.put()
        case .selector(let selector):
            selector.put()
            plugin(from: selector).put()
        }
    }

}
