//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension ModelRegistry {
    static var hasSyncableModels: Bool {
        if #available(iOS 13.0, *) {
            return models.contains { !$0.schema.isSystem }
        } else {
            return false
        }
    }
}
