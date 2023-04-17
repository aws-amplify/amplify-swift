//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Predictions.Identify.Request where Output == IdentifyEntityMatchesResult {
    public static func entitiesFromCollection(withID collectionID: String) -> Self {
        .init(kind: .detectEntitiesCollection(collectionID, .lift))
    }
}
