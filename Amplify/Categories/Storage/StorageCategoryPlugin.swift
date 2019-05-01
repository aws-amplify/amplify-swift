//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol StorageCategoryPlugin: Plugin, StorageCategoryClientBehavior
    where PluginMarker == CategoryMarker.Storage { }

public struct AnyStorageCategoryPlugin: StorageCategoryPlugin, PluginInitializable {
    public typealias PluginInitializableMarker = CategoryMarker.Storage

    // Generic plugin behaviors
    public let key: PluginKey
    private let _configure: (Any) throws -> Void
    private let _reset: () -> Void

    // Holder for client-specific behaviors
    private let clientBehavior: StorageCategoryClientBehavior

    public init<P: Plugin>(instance: P) where PluginInitializableMarker == P.PluginMarker {
        guard let clientBehavior = instance as? StorageCategoryClientBehavior else {
            preconditionFailure("Plugin does not conform to StorageCategoryClientBehavior")
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

    // Client API
    public func stub() {
        clientBehavior.stub()
    }
}
