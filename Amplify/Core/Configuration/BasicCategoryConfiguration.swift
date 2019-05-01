//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct BasicCategoryConfiguration: CategoryConfiguration {
    /// A map of plugins to their specific configurations
    public private(set) var plugins: [PluginKey: Any]

    public init(plugins: [PluginKey: Any]) {
        self.plugins = plugins
    }
}
