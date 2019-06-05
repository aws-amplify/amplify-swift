//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol HubCategoryPlugin: Plugin, HubCategoryClientBehavior { }

public struct AnyHubCategoryPlugin: HubCategoryPlugin, PluginInitializable {
    public typealias PluginInitializableMarker = CategoryMarker.Hub

    // Generic plugin behaviors
    public let key: PluginKey
    private let _configure: (Any) throws -> Void
    private let _reset: () -> Void

    // Holder for client-specific behaviors
    private let clientBehavior: HubCategoryClientBehavior

    public init<P: Plugin>(instance: P) {
        guard let clientBehavior = instance as? HubCategoryClientBehavior else {
            preconditionFailure("Plugin does not conform to HubCategoryClientBehavior")
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
    public func dispatch(to channel: HubChannel, payload: HubPayload) {
        clientBehavior.dispatch(to: channel, payload: payload)
    }
}
