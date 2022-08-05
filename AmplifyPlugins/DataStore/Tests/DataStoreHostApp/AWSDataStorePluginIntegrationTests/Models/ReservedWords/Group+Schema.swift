//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension Group {
    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
    }

    public static let keys = CodingKeys.self
    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let group = Group.keys

        model.listPluralName = "Groups"
        model.syncPluralName = "Groups"

        model.fields(
            .id()
        )
    }
}
