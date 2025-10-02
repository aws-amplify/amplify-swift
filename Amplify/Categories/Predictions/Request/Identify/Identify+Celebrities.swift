//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Predictions.Identify {
    enum Celebrities {}
}

public extension Predictions.Identify.Request where Output == Predictions.Identify.Celebrities.Result {
    nonisolated(unsafe) static let celebrities = Self(
        kind: .detectCelebrities(.lift)
    )
}
