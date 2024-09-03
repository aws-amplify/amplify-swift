//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension ModelSyncMetadata {

    // MARK: - CodingKeys

    enum CodingKeys: String, ModelKey {
        case id
        case lastSync
        case syncPredicate
    }

    static let keys = CodingKeys.self

    // MARK: - ModelSchema

    static let schema = defineSchema { definition in

        definition.attributes(.isSystem)

        definition.fields(
            .id(),
            .field(keys.lastSync, is: .optional, ofType: .int),
            .field(keys.syncPredicate, is: .optional, ofType: .string)
        )
    }
}
