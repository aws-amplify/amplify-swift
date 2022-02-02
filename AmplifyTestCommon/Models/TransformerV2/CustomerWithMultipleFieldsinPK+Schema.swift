//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension CustomerWithMultipleFieldsinPK {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case dob
    case date
    case time
    case phoneNumber
    case priority
    case height
    case firstName
    case lastName
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let customerWithMultipleFieldsinPK = CustomerWithMultipleFieldsinPK.keys

    model.pluralName = "CustomerWithMultipleFieldsinPKs"

    model.attributes(
      .index(fields: ["id", "dob", "date", "time", "phoneNumber", "priority", "height"], name: nil)
    )

    model.fields(
      .id(),
      .field(customerWithMultipleFieldsinPK.dob, is: .required, ofType: .dateTime),
      .field(customerWithMultipleFieldsinPK.date, is: .required, ofType: .date),
      .field(customerWithMultipleFieldsinPK.time, is: .required, ofType: .time),
      .field(customerWithMultipleFieldsinPK.phoneNumber, is: .required, ofType: .int),
      .field(customerWithMultipleFieldsinPK.priority, is: .required, ofType: .enum(type: Priority.self)),
      .field(customerWithMultipleFieldsinPK.height, is: .required, ofType: .double),
      .field(customerWithMultipleFieldsinPK.firstName, is: .optional, ofType: .string),
      .field(customerWithMultipleFieldsinPK.lastName, is: .optional, ofType: .string),
      .field(customerWithMultipleFieldsinPK.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(customerWithMultipleFieldsinPK.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}
