//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Predictions.Identify {
    enum Entities {}
}

public extension Predictions.Identify.Request where Output == Predictions.Identify.Entities.Result {
    nonisolated(unsafe) static let entities = Self(
        kind: .detectEntities(.lift)
    )
}
