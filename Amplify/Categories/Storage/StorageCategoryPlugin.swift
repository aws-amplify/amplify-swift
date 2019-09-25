//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol StorageCategoryPlugin: Plugin, StorageCategoryClientBehavior { }

public extension StorageCategoryPlugin {
    var categoryType: CategoryType {
        return .storage
    }
}
