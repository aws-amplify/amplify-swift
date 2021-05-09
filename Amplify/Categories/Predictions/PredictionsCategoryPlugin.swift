//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public protocol PredictionsCategoryPlugin: Plugin, PredictionsCategoryBehavior { }

public extension PredictionsCategoryPlugin {

    /// <#Description#>
    var categoryType: CategoryType {
        return .predictions
    }
}
