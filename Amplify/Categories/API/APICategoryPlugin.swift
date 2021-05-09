//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public protocol APICategoryPlugin: Plugin, APICategoryBehavior { }

public extension APICategoryPlugin {

    /// <#Description#>
    var categoryType: CategoryType {
        return .api
    }
}
