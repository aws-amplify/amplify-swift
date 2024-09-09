//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Customer9 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case phoneNumber
    case accountRepresentativeId
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let customer9 = Customer9.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Customer9s"
    model.syncPluralName = "Customer9s"

    model.attributes(
      .index(fields: ["accountRepresentativeId", "name"], name: "customer9sByAccountRepresentativeIdAndName"),
      .primaryKey(fields: [customer9.id])
    )

    model.fields(
      .field(customer9.id, is: .required, ofType: .string),
      .field(customer9.name, is: .optional, ofType: .string),
      .field(customer9.phoneNumber, is: .optional, ofType: .string),
      .field(customer9.accountRepresentativeId, is: .required, ofType: .string),
      .field(customer9.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(customer9.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Customer9> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Customer9: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Customer9 {
  var id: FieldPath<String>   {
      string("id")
    }
  var name: FieldPath<String>   {
      string("name")
    }
  var phoneNumber: FieldPath<String>   {
      string("phoneNumber")
    }
  var accountRepresentativeId: FieldPath<String>   {
      string("accountRepresentativeId")
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
