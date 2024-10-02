//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Salary18 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case wage
    case currency
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let salary18 = Salary18.keys

    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Admin"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Salary18s"
    model.syncPluralName = "Salary18s"

    model.attributes(
      .primaryKey(fields: [salary18.id])
    )

    model.fields(
      .field(salary18.id, is: .required, ofType: .string),
      .field(salary18.wage, is: .optional, ofType: .double),
      .field(salary18.currency, is: .optional, ofType: .string),
      .field(salary18.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(salary18.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Salary18> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Salary18: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Salary18 {
  var id: FieldPath<String>   {
      string("id")
    }
  var wage: FieldPath<Double>   {
      double("wage")
    }
  var currency: FieldPath<String>   {
      string("currency")
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
