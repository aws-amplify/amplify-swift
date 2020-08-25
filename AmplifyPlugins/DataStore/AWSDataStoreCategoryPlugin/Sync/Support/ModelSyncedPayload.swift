//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ModelSyncedPayload {
    let modelName: String
    var isFullSync: Bool
    var isDeltaSync: Bool
    var createCount: Int
    var updateCount: Int
    var deleteCount: Int

    init(modelName: String,
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
