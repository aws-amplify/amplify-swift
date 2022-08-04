//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension Row {
    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case group
    }

    public static let keys = CodingKeys.self
    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let row = Row.keys

        model.listPluralName = "Rows"
        model.syncPluralName = "Rows"

        model.fields(
            .id(),
            .belongsTo(row.group, is: .required, ofType: Group.self, targetName: "rowGroupId")
        )
    }
}
