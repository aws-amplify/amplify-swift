//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AnalyticsCategoryPlugin: Plugin, AnalyticsCategoryClientBehavior { }

public protocol AnalyticsPluginSelector: PluginSelector, AnalyticsCategoryClientBehavior { }

public struct AnyAnalyticsCategoryPlugin: AnalyticsCategoryPlugin, PluginInitializable {

    public typealias PluginInitializableMarker = CategoryMarker.Analytics

    // Generic plugin behaviors
    public let key: PluginKey
    private let _configure: (Any) throws -> Void
    private let _reset: () -> Void

    // Holder for client-specific behaviors
    private let clientBehavior: AnalyticsCategoryClientBehavior

    public init<P: Plugin>(instance: P) {
        guard let clientBehavior = instance as? AnalyticsCategoryClientBehavior else {
            preconditionFailure("Plugin does not conform to AnalyticsCategoryClientBehavior")
        }

        self.clientBehavior = clientBehavior

        key = instance.key
        _configure = instance.configure
        _reset = instance.reset
    }

    public func configure(using configuration: Any) throws {
        try _configure(configuration)
    }

    public func reset() {
        _reset()
    }

    // MARK: - Client behavior

    public func disable() {
        clientBehavior.disable()
    }

    public func enable() {
        clientBehavior.enable()
    }

    public func record(_ name: String) {
        clientBehavior.record(name)
    }

    public func record(_ event: AnalyticsEvent) {
        clientBehavior.record(event)
    }

    public func update(analyticsProfile: AnalyticsProfile) {
        clientBehavior.update(analyticsProfile: analyticsProfile)
    }
}
