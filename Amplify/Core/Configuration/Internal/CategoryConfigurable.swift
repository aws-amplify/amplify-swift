//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

protocol CategoryConfigurable: class, CategoryTypeable {

    /// true if the category has already been configured
    var isConfigured: Bool { get set }

    /// Configures the category and added plugins using `configuration`
    ///
    /// - Parameter configuration: The CategoryConfiguration
    /// - Throws:
    ///   - PluginError.noSuchPlugin: If the specified configuration references a plugin that has not been added
    ///     using `add(plugin:)`
    ///   - PluginError.pluginConfigurationError: If any plugin encounters an error during configuration
    func configure(using configuration: CategoryConfiguration) throws

    /// Convenience method for configuring the category using the top-level AmplifyConfiguration
    ///
    /// - Parameter amplifyConfiguration: The AmplifyConfiguration
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If any plugin encounters an error during configuration
    func configure(using amplifyConfiguration: AmplifyConfiguration) throws

    /// Clears the category configurations, and invokes `reset` on each added plugin
    func reset(onComplete: @escaping (() -> Void))

}
