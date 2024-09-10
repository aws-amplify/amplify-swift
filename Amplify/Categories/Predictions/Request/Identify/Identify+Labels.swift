//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Predictions.Identify {
    enum Labels {}
}

public extension Predictions.Identify.Request where Output == Predictions.Identify.Labels.Result {
    static func labels(type: Predictions.LabelType = .labels) -> Self {
        .init(kind: .detectLabels(type, .lift))
    }
}
