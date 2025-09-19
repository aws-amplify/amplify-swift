//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Predictions.Identify {
    enum EntityMatches {}
}

public extension Predictions.Identify.Request where Output == Predictions.Identify.EntityMatches.Result {
    static func entitiesFromCollection(withID collectionID: String) -> Self {
        .init(kind: .detectEntitiesCollection(collectionID, .lift))
    }
}
