//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol PredictionsCategoryPlugin: Plugin, PredictionsCategoryBehavior { }

public extension PredictionsCategoryPlugin {
    var categoryType: CategoryType {
        return .predictions
    }
}
