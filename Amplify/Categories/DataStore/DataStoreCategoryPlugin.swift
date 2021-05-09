//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public protocol DataStoreCategoryPlugin: Plugin, DataStoreCategoryBehavior { }

public extension DataStoreCategoryPlugin {

    /// <#Description#>
    var categoryType: CategoryType {
        return .dataStore
    }
}
