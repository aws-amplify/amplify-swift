//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Predictions.Identify.Request where Output == IdentifyLabelsResult {
    public static func labels(type: LabelType) -> Self {
        .init(kind: .detectLabels(type, .lift))
    }
}
