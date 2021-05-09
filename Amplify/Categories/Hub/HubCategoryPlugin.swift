//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public protocol HubCategoryPlugin: Plugin, HubCategoryBehavior { }

public extension HubCategoryPlugin {

    /// <#Description#>
    var categoryType: CategoryType {
        return .hub
    }
}
