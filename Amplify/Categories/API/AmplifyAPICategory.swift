//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The API category provides a solution for making HTTP requests to REST and GraphQL endpoints.
final public class AmplifyAPICategory {

    var plugins = [PluginKey: APICategoryPlugin]()

    /// Returns the plugin added to the category, if only one plugin is added. Accessing this property if no plugins
    /// are added, or if more than one plugin is added, will cause a preconditionFailure.
    var plugin: APICategoryPlugin {
        guard isConfigured else {
            return Amplify.preconditionFailure(
                """
                \(categoryType.displayName) category is not configured. Call Amplify.configure() before using \
                any methods on the category.
                """
            )
        }

        guard !plugins.isEmpty else {
            return Amplify.preconditionFailure("No plugins added to \(categoryType.displayName) category.")
        }

        guard plugins.count == 1 else {
            return Amplify.preconditionFailure(
                """
                More than 1 plugin added to \(categoryType.displayName) category. \
                You must invoke operations on this category by getting the plugin you want, as in:
                #"Amplify.\(categoryType.displayName).getPlugin(for: "ThePluginKey").foo()
                """
            )
        }

        return plugins.first!.value
    }

    /// `true` if this category has been configured with `Amplify.configure()`.
    ///
    /// - Warning: This property is intended for use by plugin developers.
    public var isConfigured = false

}
