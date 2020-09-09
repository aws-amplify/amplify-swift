//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct ModelSyncedEvent {
    let modelName: String
    var isFullSync: Bool
    var isDeltaSync: Bool
    let createCount: Int
    let updateCount: Int
    let deleteCount: Int

    public init(modelName: String,
                isFullSync: Bool = false,
                isDeltaSync: Bool = false,
                createCount: Int = 0,
                updateCount: Int = 0,
                deleteCount: Int = 0) {
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
