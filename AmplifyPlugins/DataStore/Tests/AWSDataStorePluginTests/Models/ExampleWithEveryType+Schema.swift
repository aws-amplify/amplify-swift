//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension ExampleWithEveryType {

    // MARK: - CodingKeys

    enum CodingKeys: String, ModelKey {
        case id
        case stringField
        case intField
        case doubleField
        case boolField
        case dateField
        case enumField
        case nonModelField
        case arrayOfStringsField
    }

    static let keys = CodingKeys.self

    // MARK: - ModelSchema

    static let schema = defineSchema { model in
        let example = ExampleWithEveryType.keys

        model.listPluralName = "ExampleWithEveryTypes"
        model.syncPluralName = "ExampleWithEveryTypes"

        model.fields(
            .id(),
            .field(example.stringField, is: .required, ofType: .string),
            .field(example.intField, is: .required, ofType: .int),
            .field(example.doubleField, is: .required, ofType: .double),
            .field(example.boolField, is: .required, ofType: .bool),
            .field(example.dateField, is: .required, ofType: .date),
            .field(example.enumField, is: .required, ofType: .enum(type: ExampleEnum.self)),
            .field(example.nonModelField, is: .required, ofType: .embedded(type: ExampleNonModelType.self)),
            .field(example.arrayOfStringsField, is: .required, ofType: .embeddedCollection(of: [String].self))
        )
    }

}
