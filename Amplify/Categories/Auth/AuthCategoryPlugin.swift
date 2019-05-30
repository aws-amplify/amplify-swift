//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AuthCategoryPlugin: Plugin, AuthCategoryClientBehavior { }

public struct AnyAuthCategoryPlugin: AuthCategoryPlugin, PluginInitializable {
    public typealias PluginInitializableMarker = CategoryMarker.Auth

    // Generic plugin behaviors
    public let key: PluginKey
    private let _configure: (Any) throws -> Void
    private let _reset: () -> Void

    // Holder for client-specific behaviors
    private let clientBehavior: AuthCategoryClientBehavior

    public init<P: Plugin>(instance: P) {
        guard let clientBehavior = instance as? AuthCategoryClientBehavior else {
            preconditionFailure("Plugin does not conform to AuthCategoryClientBehavior")
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

    public func stub() {
        clientBehavior.stub()
    }
}
