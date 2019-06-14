//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AuthCategory: AuthCategoryClientBehavior {
    private func plugin(from selector: AuthPluginSelector) -> AuthCategoryPlugin {
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

    public func stub() {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.stub()
        case .selector(let selector):
            selector.stub()
            plugin(from: selector).stub()
        }
    }
}
