//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

// swiftlint:disable all
import Foundation

public extension Transaction {
    // MARK: - CodingKeys
    enum CodingKeys: String, ModelKey {
        case id
    }

    static let keys = CodingKeys.self
    // MARK: - ModelSchema

    static let schema = defineSchema { model in
        let transaction = Transaction.keys

        model.listPluralName = "Transactions"
        model.syncPluralName = "Transactions"

        model.fields(
            .id()
        )
    }
}
