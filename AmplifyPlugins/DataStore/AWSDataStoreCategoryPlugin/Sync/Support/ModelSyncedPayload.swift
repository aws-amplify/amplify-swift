//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ModelSyncedPayload {
    var modelName: String
    var isFullSync: Bool
    var isDeltaSync: Bool
    var createCount: Int
    var updateCount: Int
    var deleteCount: Int

    init(modelName: String? = nil,
         isFullSync: Bool? = nil,
         isDeltaSync: Bool? = nil,
         createCount: Int? = nil,
         updateCount: Int? = nil,
         deleteCount: Int? = nil) {
        self.modelName = modelName ?? ""
        self.isFullSync = isFullSync ?? false
        self.isDeltaSync = isDeltaSync ?? false
        self.createCount = createCount ?? 0
        self.updateCount = updateCount ?? 0
        self.deleteCount = deleteCount ?? 0
    }
}
