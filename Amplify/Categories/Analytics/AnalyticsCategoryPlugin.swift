//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol AnalyticsCategoryPlugin: Plugin, AnalyticsCategoryClientBehavior { }

public extension AnalyticsCategoryPlugin {
    var categoryType: CategoryType {
        return .analytics
    }
}
