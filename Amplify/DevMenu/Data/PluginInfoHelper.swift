//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Helper class to fetch Amplify plugin information
@available(iOS 13.0.0, *)
struct PluginInfoHelper {

    static let versionNotAvailable = "Version not available"

    static func getPluginInformation() -> [PluginInfoItem] {
        var pluginList = [PluginInfoItem]()

        // Add Analytics plugins information
        for pluginKey in Amplify.Analytics.plugins.keys {
            if let versionable = (try? Amplify.Auth.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionable.version))
            } else {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionNotAvailable))
            }
        }

        // Add API plugins information
        if let apiCategoryPlugin = Amplify.API as? AmplifyAPICategory {
            for pluginKey in apiCategoryPlugin.plugins.keys {
                if let versionable = (try? Amplify.Auth.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                    pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionable.version))
                } else {
                    pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionNotAvailable))
                }
            }
        }

        // Add Auth plugins information
        for pluginKey in Amplify.Analytics.plugins.keys {
            if let versionable = (try? Amplify.Auth.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionable.version))
            } else {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionNotAvailable))
            }
        }

        // Add DataStore plugins information
        for pluginKey in Amplify.DataStore.plugins.keys {
            if let versionable = (try? Amplify.DataStore.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionable.version))
            } else {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionNotAvailable))
            }
        }

        // Add Hub plugins information
        for pluginKey in Amplify.Hub.plugins.keys {
            if let versionable = (try? Amplify.DataStore.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionable.version))
            } else {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionNotAvailable))
            }
        }

        // Add Logging plugins information
        if let versionable = Amplify.Logging.plugin as? AmplifyVersionable {
            pluginList.append(PluginInfoItem(displayName: Amplify.Logging.plugin.key, information: versionable.version))
        } else {
            pluginList.append(PluginInfoItem(displayName: Amplify.Logging.plugin.key, information: versionNotAvailable))
        }

        // Add Predictions plugins information
        for pluginKey in Amplify.Predictions.plugins.keys {
            if let versionable = (try? Amplify.Predictions.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionable.version))
            } else {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionNotAvailable))
            }
        }

        // Add Storage plugins information
        for pluginKey in Amplify.Storage.plugins.keys {
            if let versionable = (try? Amplify.Predictions.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionable.version))
            } else {
                pluginList.append(PluginInfoItem(displayName: pluginKey, information: versionNotAvailable))
            }
        }

        return pluginList
    }
}
