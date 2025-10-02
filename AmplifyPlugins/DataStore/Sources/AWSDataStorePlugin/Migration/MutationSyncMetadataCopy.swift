//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@preconcurrency import Amplify
import Foundation

extension MutationSyncMetadataMigration {
    struct MutationSyncMetadataCopy: Model {
        let id: String
        var deleted: Bool
        var lastChangedAt: Int64
        var version: Int

        // MARK: - CodingKeys

        enum CodingKeys: String, ModelKey {
            case id
            case deleted
            case lastChangedAt
            case version
        }

        static let keys = CodingKeys.self

        // MARK: - ModelSchema

        static let schema = defineSchema { definition in
            let sync = MutationSyncMetadataCopy.keys

            definition.attributes(.isSystem)

            definition.fields(
                .id(),
                .field(sync.deleted, is: .required, ofType: .bool),
                .field(sync.lastChangedAt, is: .required, ofType: .int),
                .field(sync.version, is: .required, ofType: .int)
            )
        }
    }
}
