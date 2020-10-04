//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Used as HubPayload for the `ModelSynced`
public struct ModelSyncedEvent {
    /// the name of the model that was synced
    public let modelName: String
    /// `true` if the model was synced with a "full" query to retrieve all models
    public let isFullSync: Bool
    /// `true` if the model was synced with a "delta" query to retrieve changes since the last sync
    public let isDeltaSync: Bool
    /// the number of new model instances added to the local store
    public let added: Int
    /// the number of existing model instances updated in the local store
    public let updated: Int
    /// the number of model instances deleted from the local store
    public let deleted: Int

    public init(modelName: String,
                isFullSync: Bool,
                isDeltaSync: Bool,
                added: Int,
                updated: Int,
                deleted: Int) {
        self.modelName = modelName
        self.isFullSync = isFullSync
        self.isDeltaSync = isDeltaSync
        self.added = added
        self.updated = updated
        self.deleted = deleted
    }
}

extension ModelSyncedEvent {
    struct Builder {
        var modelName: String
        var isFullSync: Bool
        var isDeltaSync: Bool
        var added: AtomicValue<Int>
        var updated: AtomicValue<Int>
        var deleted: AtomicValue<Int>

        init() {
            self.modelName = ""
            self.isFullSync = false
            self.isDeltaSync = false
            self.added = AtomicValue(initialValue: 0)
            self.updated = AtomicValue(initialValue: 0)
            self.deleted = AtomicValue(initialValue: 0)
        }

        func build() -> ModelSyncedEvent {
            ModelSyncedEvent(
                modelName: modelName,
                isFullSync: isFullSync,
                isDeltaSync: isDeltaSync,
                added: added.get(),
                updated: updated.get(),
                deleted: deleted.get()
            )
        }
    }
}
