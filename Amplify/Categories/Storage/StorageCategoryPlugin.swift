//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public protocol StorageCategoryPlugin: Plugin, StorageCategoryBehavior { }

public extension StorageCategoryPlugin {

    /// <#Description#>
    var categoryType: CategoryType {
        return .storage
    }
}
