//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension Group {
    // MARK: - CodingKeys
    enum CodingKeys: String, ModelKey {
        case id
    }

    static let keys = CodingKeys.self
    // MARK: - ModelSchema

    static let schema = defineSchema { model in
        let group = Group.keys

        model.listPluralName = "Groups"
        model.syncPluralName = "Groups"

        model.fields(
            .id()
        )
    }
}
