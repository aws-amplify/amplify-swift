//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Used as HubPayload for the `ModelSynced`
public struct ModelSyncedEvent {
    /// Name of model that have been synced
    public let modelName: String
    /// Notify the type of sync: `full` or `delta`
    public var isFullSync: Bool
    public var isDeltaSync: Bool
    /// Count of mutationType of model instances that have been synced: `create`, `update`, `delete`
    public let createCount: Int
    public let updateCount: Int
    public let deleteCount: Int

    public init(modelName: String,
                isFullSync: Bool,
                isDeltaSync: Bool,
                createCount: Int,
                updateCount: Int,
                deleteCount: Int) {
        self.modelName = modelName
        self.isFullSync = isFullSync
        self.isDeltaSync = isDeltaSync
        self.createCount = createCount
        self.updateCount = updateCount
        self.deleteCount = deleteCount
    }
}

extension ModelSyncedEvent {
    struct Builder {
        var modelName: String
        var isFullSync: Bool
        var isDeltaSync: Bool
        var createCount: AtomicValue<Int>
        var updateCount: AtomicValue<Int>
        var deleteCount: AtomicValue<Int>

        init() {
            self.modelName = ""
            self.isFullSync = false
            self.isDeltaSync = false
            self.createCount = AtomicValue.init(initialValue: 0)
            self.updateCount = AtomicValue.init(initialValue: 0)
            self.deleteCount = AtomicValue.init(initialValue: 0)
        }

        func build() -> ModelSyncedEvent {
            ModelSyncedEvent(
                modelName: modelName,
                isFullSync: isFullSync,
                isDeltaSync: isDeltaSync,
                createCount: createCount.get(),
                updateCount: updateCount.get(),
                deleteCount: deleteCount.get()
            )
        }
    }
}
