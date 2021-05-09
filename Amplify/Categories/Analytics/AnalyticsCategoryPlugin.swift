//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public protocol AnalyticsCategoryPlugin: Plugin, AnalyticsCategoryBehavior { }

public extension AnalyticsCategoryPlugin {

    /// <#Description#>
    var categoryType: CategoryType {
        return .analytics
    }
}
