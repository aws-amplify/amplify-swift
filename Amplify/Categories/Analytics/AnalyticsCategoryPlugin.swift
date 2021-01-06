//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AnalyticsCategoryPlugin: Plugin, AnalyticsCategoryBehavior { }

public extension AnalyticsCategoryPlugin {
    var categoryType: CategoryType {
        return .analytics
    }
}
