//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension CustomerWithDateInPK {
    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case dob
        case firstName
        case lastName
        case createdAt
        case updatedAt
    }

    public static let keys = CodingKeys.self
    //  MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let customerWithDateInPK = CustomerWithDateInPK.keys

        model.pluralName = "CustomerWithDateInPKs"

        model.attributes(
            .index(fields: ["id", "dob"], name: nil)
        )

        model.fields(
            .id(),
            .field(customerWithDateInPK.dob, is: .required, ofType: .dateTime),
            .field(customerWithDateInPK.firstName, is: .optional, ofType: .string),
            .field(customerWithDateInPK.lastName, is: .optional, ofType: .string),
            .field(customerWithDateInPK.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
            .field(customerWithDateInPK.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
        )
    }
}

