//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Foundation
import Amplify

extension Transaction {
    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
    }

    public static let keys = CodingKeys.self
    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let transaction = Transaction.keys

        model.listPluralName = "Transactions"
        model.syncPluralName = "Transactions"

        model.fields(
            .id()
        )
    }
}
