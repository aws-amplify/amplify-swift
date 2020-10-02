//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Used as HubPayload for the `ModelSynced`
/// - `modelName` (String): the name of the model that was synced
/// - `isFullSync` (Bool): `true` if the model was synced with a "full" query to retrieve all models
/// - `isDeltaSync` (Bool): `true` if the model was synced with a "delta" query to retrieve changes since the last sync
/// - `createCount` (Int): the number of new model instances added to the local store
/// - `updateCount` (Int): the number of existing model instances updated in the local store
/// - `deleteCount` (Int): the number of model instances deleted from the local store
public struct ModelSyncedEvent {
    public let modelName: String
    public let isFullSync: Bool
    public let isDeltaSync: Bool
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
            self.createCount = AtomicValue(initialValue: 0)
            self.updateCount = AtomicValue(initialValue: 0)
            self.deleteCount = AtomicValue(initialValue: 0)
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
