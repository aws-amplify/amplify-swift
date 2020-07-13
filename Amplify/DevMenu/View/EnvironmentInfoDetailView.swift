//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// Detail view showing environment information
@available(iOS 13.0.0, *)
struct EnvironmentInfoDetailView: View {
    private let screenTitle  = "Environment Information"
    private let amplifyEnvSectionTitle  = "Amplify Environment Information"
    private let devEnvSectionTitle  = "Developer Environment Information"

    /// Lists containing items belonging to two sections : Amplify and Developer Environment Informatoin
    private var amplifyEnvSectionItems = [EnvironmentInfoItem]()
    private var devEnvSectionItems = [EnvironmentInfoItem]()

    init() {
        // TODO : Read environment information from json file and
        // call populateDevEnvSectionItems()
        populateAmplifyEnvSectionItems()
    }

    var body: some View {
        SwiftUI.List {
            Section(header: Text(amplifyEnvSectionTitle), footer: EmptyView()) {
                if amplifyEnvSectionItems.isEmpty {
                    NoItemView()
                } else {
                    ForEach(amplifyEnvSectionItems) { listItem in
                        InfoRow(item: listItem)
                    }
                }
            }
            Section(header: Text(devEnvSectionTitle), footer: EmptyView()) {
                if devEnvSectionItems.isEmpty {
                    NoItemView()
                } else {
                    ForEach(devEnvSectionItems) { listItem in
                        InfoRow(item: listItem)
                    }
                }
            }
        }
        .navigationBarTitle(screenTitle)
        .listStyle(GroupedListStyle())
    }

    private mutating func populateDevEnvSectionItems(devEnvInfo: DevEnvironmentInfo) {
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: EnvironmentInfoItemType.nodejsVersion.key,
            value: devEnvInfo.nodejsVersion))
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: EnvironmentInfoItemType.npmVersion.key,
            value: devEnvInfo.npmVersion))
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: EnvironmentInfoItemType.amplifyCLIVersion.key,
            value: devEnvInfo.amplifyCLIVersion))
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: EnvironmentInfoItemType.podVersion.key,
            value: devEnvInfo.podVersion))
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: EnvironmentInfoItemType.xcodeVersion.key,
            value: devEnvInfo.xcodeVersion))
        devEnvSectionItems.append(EnvironmentInfoItem(
            key: EnvironmentInfoItemType.osVersion.key,
            value: devEnvInfo.osVersion))
    }

    private mutating func populateAmplifyEnvSectionItems() {
        // Add Analytics plugins information
        for pluginKey in Amplify.Analytics.plugins.keys {
            if let versionable = (try? Amplify.Auth.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                amplifyEnvSectionItems.append(EnvironmentInfoItem(key: pluginKey, value: versionable.version))
            }
        }

        // Add API plugins information
        if let apiCategoryPlugin = Amplify.API as? AmplifyAPICategory {
            for pluginKey in apiCategoryPlugin.plugins.keys {
                if let versionable = (try? Amplify.Auth.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                    amplifyEnvSectionItems.append(EnvironmentInfoItem(key: pluginKey, value: versionable.version))
                }
            }
        }

        // Add Auth plugins information
        for pluginKey in Amplify.Analytics.plugins.keys {
            if let versionable = (try? Amplify.Auth.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                amplifyEnvSectionItems.append(EnvironmentInfoItem(key: pluginKey, value: versionable.version))
            }
        }

        // Add DataStore plugins information
        for pluginKey in Amplify.DataStore.plugins.keys {
            if let versionable = (try? Amplify.DataStore.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                amplifyEnvSectionItems.append(EnvironmentInfoItem(key: pluginKey, value: versionable.version))
            }
        }

        // Add Hub plugins information
        for pluginKey in Amplify.Hub.plugins.keys {
            if let versionable = (try? Amplify.DataStore.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                amplifyEnvSectionItems.append(EnvironmentInfoItem(key: pluginKey, value: versionable.version))
            }
        }

        // Add Logging plugins information
        if let versionable = Amplify.Logging.plugin as? AmplifyVersionable {
            amplifyEnvSectionItems.append(EnvironmentInfoItem(
                                                key: Amplify.Logging.plugin.key,
                                                value: versionable.version))
        }

        // Add Predictions plugins information
        for pluginKey in Amplify.Predictions.plugins.keys {
            if let versionable = (try? Amplify.Predictions.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                amplifyEnvSectionItems.append(EnvironmentInfoItem(key: pluginKey, value: versionable.version))
            }
        }

        // Add Storage plugins information
        for pluginKey in Amplify.Storage.plugins.keys {
            if let versionable = (try? Amplify.Predictions.getPlugin(for: pluginKey)) as? AmplifyVersionable {
                amplifyEnvSectionItems.append(EnvironmentInfoItem(key: pluginKey, value: versionable.version))
            }
        }
    }

}

@available(iOS 13.0.0, *)
struct EnvironmentInfoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EnvironmentInfoDetailView()
    }
}

@available(iOS 13.0, *)
struct NoItemView: View {
    var body: some View {
        HStack {
            Text("Information not available").padding(15)
            Spacer()
        }
    }
}
