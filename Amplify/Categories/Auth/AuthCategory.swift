//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// - Note: `@unchecked Sendable` to satisfy the `Sendable` requirement that the category behavior
///   protocol now carries.
///
///   Unchecked in the literal sense: `plugins` and `isConfigured` are plain mutable state with no lock.
///   `add(plugin:)` cannot race a configured category — it throws once `isConfigured` is set — but
///   `removePlugin(for:)` mutates `plugins` with no such guard and no lock, so it can race a concurrent
///   read. That exposure predates this annotation; the annotation only stops the compiler from asking
///   about it.
public final class AuthCategory: Category, @unchecked Sendable {

    public let categoryType =  CategoryType.auth

    var plugins = [PluginKey: AuthCategoryPlugin]()

    /// Returns the plugin added to the category, if only one plugin is added. Accessing this property if no plugins
    /// are added, or if more than one plugin is added, will cause a preconditionFailure.
    var plugin: AuthCategoryPlugin {
        guard isConfigured else {
            return Fatal.preconditionFailure(
                """
                \(categoryType.displayName) category is not configured. Call Amplify.configure() before using \
                any methods on the category.
                """
            )
        }

        guard !plugins.isEmpty else {
            return Fatal.preconditionFailure("No plugins added to \(categoryType.displayName) category.")
        }

        guard plugins.count == 1 else {
            return Fatal.preconditionFailure(
                """
                More than 1 plugin added to \(categoryType.displayName) category. \
                You must invoke operations on this category by getting the plugin you want, as in:
                #"Amplify.\(categoryType.displayName).getPlugin(for: "ThePluginKey").foo()
                """
            )
        }

        return plugins.first!.value
    }

    var isConfigured = false

    /// The configured plugin, or `nil` when this category has no plugin to serve a request.
    ///
    /// A non-trapping counterpart to ``plugin``. Reading ``plugin`` before configuration, or with no
    /// plugin registered, trips a `preconditionFailure` and aborts the process. That is the right
    /// behaviour for application code — it is a programmer error — but not for the AWS plugin modules,
    /// which hold long-lived clients that can outlive `Amplify.reset()`. For those, a missing Auth
    /// category is recoverable and should surface as a thrown error.
    ///
    /// Returning the plugin rather than a Boolean is what makes this safe to act on: the caller captures
    /// the plugin once and invokes it directly, so a concurrent `Amplify.reset()` cannot land between a
    /// check and a second read of `Amplify.Auth`. A Boolean flag would leave exactly that window open.
    ///
    /// More than one registered plugin still traps, deliberately — that is a genuine misconfiguration
    /// rather than a state a client can be legitimately called in.
    @_spi(InternalAmplifyConfiguration)
    public var configuredPlugin: AuthCategoryPlugin? {
        let registered = plugins
        guard isConfigured, !registered.isEmpty else { return nil }
        guard registered.count == 1 else { return plugin }
        return registered.first?.value
    }

    // MARK: - Plugin handling

    /// Adds `plugin` to the list of Plugins that implement functionality for this category.
    ///
    /// - Parameter plugin: The Plugin to add
    public func add(plugin: AuthCategoryPlugin) throws {
        let key = plugin.key
        guard !key.isEmpty else {
            let pluginDescription = String(describing: plugin)
            let error = AuthError.configuration(
                "Plugin \(pluginDescription) has an empty `key`.",
                "Set the `key` property for \(String(describing: plugin))"
            )
            throw error
        }

        guard !isConfigured else {
            let pluginDescription = String(describing: plugin)
            let error = ConfigurationError.amplifyAlreadyConfigured(
                "\(pluginDescription) cannot be added after `Amplify.configure()`.",
                "Do not add plugins after calling `Amplify.configure()`."
            )
            throw error
        }

        plugins[plugin.key] = plugin
    }

    /// Returns the added plugin with the specified `key` property.
    ///
    /// - Parameter key: The PluginKey (String) of the plugin to retrieve
    /// - Returns: The wrapped plugin
    public func getPlugin(for key: PluginKey) throws -> AuthCategoryPlugin {
        guard let plugin = plugins[key] else {
            let keys = plugins.keys.joined(separator: ", ")
            let error = AuthError.configuration(
                "No plugin has been added for '\(key)'.",
                "Either add a plugin for '\(key)', or use one of the known keys: \(keys)"
            )
            throw error
        }
        return plugin
    }

    /// Removes the plugin registered for `key` from the list of Plugins that implement functionality for this category.
    /// If no plugin has been added for `key`, no action is taken, making this method safe to call multiple times.
    ///
    /// - Parameter key: The key used to `add` the plugin
    public func removePlugin(for key: PluginKey) {
        plugins.removeValue(forKey: key)
    }
}

extension AuthCategory: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
