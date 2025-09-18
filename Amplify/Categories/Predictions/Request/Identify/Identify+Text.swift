//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Predictions.Identify {
    enum Text {}
}

public extension Predictions.Identify.Request where Output == Predictions.Identify.Text.Result {
    nonisolated(unsafe) static let text = Self(
        kind: .detectText(.lift)
    )
}
