//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors associated with configuring and inspecting Amplify Plugins
public enum PluginError {

    /// The plugin's `key` property is empty
    case emptyKey(ErrorDescription, RecoverySuggestion)

    /// The selector factory being assigned to a category is invalid
    case invalidSelectorFactory(ErrorDescription, RecoverySuggestion)

    /// A plugin is being added to the wrong category
    case mismatchedPlugin(ErrorDescription, RecoverySuggestion)

    /// The plugin specified by `getPlugin(key)` does not exist
    case noSuchPlugin(ErrorDescription, RecoverySuggestion)

    /// An attempt was made to add a plugin to a category that already had one plugin, without first registering a
    /// PluginSelectorFactory
    case noSelector(ErrorDescription, RecoverySuggestion)

    /// The plugin encountered an error during configuration
    case pluginConfigurationError(ErrorDescription, RecoverySuggestion)
}

extension PluginError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .emptyKey(let description, _),
             .invalidSelectorFactory(let description, _),
             .mismatchedPlugin(let description, _),
             .noSuchPlugin(let description, _),
             .noSelector(let description, _),
             .pluginConfigurationError(let description, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .emptyKey(_, let recoverySuggestion),
             .invalidSelectorFactory(_, let recoverySuggestion),
             .mismatchedPlugin(_, let recoverySuggestion),
             .noSuchPlugin(_, let recoverySuggestion),
             .noSelector(_, let recoverySuggestion),
             .pluginConfigurationError(_, let recoverySuggestion):
            return recoverySuggestion
        }
    }
}
