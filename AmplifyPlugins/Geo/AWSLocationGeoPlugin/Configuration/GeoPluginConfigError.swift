//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

typealias GeoPluginErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct GeoPluginConfigError {
    static func configurationInvalid(section: AWSLocationGeoPluginConfiguration.Section) -> PluginError {
        PluginError.pluginConfigurationError(
            "Unable to decode \(section.key) configuration.",
            "Make sure the \(section.key) configuration is a JSONValue."
        )
    }

    // MARK: - Region
    static let regionMissing = PluginError.pluginConfigurationError(
        "Region is missing",
        "Add region to the configuration"
    )

    static let regionInvalid = PluginError.pluginConfigurationError(
        "Region is invalid",
        "Ensure Region is a valid region value"
    )

    static let regionEmpty = PluginError.pluginConfigurationError(
        "Region is empty",
        "Ensure should not be empty"
    )

    // MARK: - Default
    static func defaultMissing(section: AWSLocationGeoPluginConfiguration.Section) -> PluginError {
        PluginError.pluginConfigurationError(
            "Default \(section.item) is missing.",
            "Add default \(section.item) to the configuration."
        )
    }

    static func defaultNotString(section: AWSLocationGeoPluginConfiguration.Section) -> PluginError {
        PluginError.pluginConfigurationError(
            "Default \(section.item) is not a string.",
            "Ensure default \(section.item) is a string."
        )
    }

    static func defaultIsEmpty(section: AWSLocationGeoPluginConfiguration.Section) -> PluginError {
        PluginError.pluginConfigurationError(
            "Default \(section.item) is specified but is empty.",
            "Default \(section.item) should not be empty."
        )
    }

    // MARK: - Items
    static func itemsMissing(section: AWSLocationGeoPluginConfiguration.Section) -> PluginError {
        PluginError.pluginConfigurationError(
            "Configuration for `\(section.key)` is missing `items`.",
            "Add `items` to the \(section.key) configuration."
        )
    }

    static func itemsInvalid(section: AWSLocationGeoPluginConfiguration.Section) -> PluginError {
        PluginError.pluginConfigurationError(
            "Configuration at `\(section.key)`, `items` is not an array literal.",
            "Make sure the value for `\(section.key)`, `items` is an array literal."
        )
    }

    static func itemsIsNotStringArray(section: AWSLocationGeoPluginConfiguration.Section) -> PluginError {
        PluginError.pluginConfigurationError(
            "Configuration at `\(section.key)`, `items` is not a String array.",
            "Make sure the value for `\(section.key)`, `items` is a String array."
        )
    }

    // MARK: - Maps
    static let mapConfigMissing = """
                                     Map configuration is missing from amplifyconfiguration.json.
                                     Make sure amplifyconfiguration.json includes a `maps` section.
                                     """

    static func mapInvalid(mapName: String) -> PluginError {
        PluginError.pluginConfigurationError(
            "Configuration at `maps`, `items`, `\(mapName)` is not a dictionary literal.",
            "Make sure the value for `maps`, `items`, `\(mapName)` is a dictionary literal."
        )
    }

    static func mapStyleMissing(mapName: String) -> PluginError {
        PluginError.pluginConfigurationError(
            "Configuration at `maps`, `items`, `\(mapName)` does not include `style` literal.",
            "Make sure the value for `maps`, `items`, `\(mapName)` includes `style`."
        )
    }

    static func mapStyleIsNotString(mapName: String) -> PluginError {
        PluginError.pluginConfigurationError(
            "Configuration value at `maps`, `items`, `\(mapName)`, `style` is not a string.",
            "Ensure value value at `maps`, `items`, `\(mapName)`, `style` is a string."
        )
    }

    static func mapStyleURLInvalid(mapName: String) -> PluginError {
        PluginError.pluginConfigurationError(
            "Failed to create style URL for map \(mapName). This should not happen.",
            "Check settings for map \(mapName)."
        )
    }

    static func mapDefaultNotFound(mapName: String?) -> PluginError {
        PluginError.pluginConfigurationError(
            "Configured default map \(mapName ?? "nil") was not found in maps.",
            "Ensure the default map is included in maps."
        )
    }

    // MARK: - Search
    static let searchConfigMissing = """
                                     Search configuration is missing from amplifyconfiguration.json.
                                     Make amplifyconfiguration.json includes a `searchIndices` section.
                                     """

    static func searchDefaultNotFound(indexName: String?) -> PluginError {
        PluginError.pluginConfigurationError(
            "Configured default search index \(indexName ?? "nil") was not found in searchIndices.",
            "Ensure the default search index is included in searchIndices."
        )
    }
}
