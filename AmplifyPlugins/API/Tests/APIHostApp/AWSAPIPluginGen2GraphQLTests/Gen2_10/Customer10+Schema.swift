//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Customer10 {
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
    let customer10 = Customer10.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Customer10s"
    model.syncPluralName = "Customer10s"

    model.attributes(
      .index(fields: ["accountRepresentativeId"], name: "customer10sByAccountRepresentativeId"),
      .primaryKey(fields: [customer10.id])
    )

    model.fields(
      .field(customer10.id, is: .required, ofType: .string),
      .field(customer10.name, is: .optional, ofType: .string),
      .field(customer10.phoneNumber, is: .optional, ofType: .string),
      .field(customer10.accountRepresentativeId, is: .required, ofType: .string),
      .field(customer10.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(customer10.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Customer10> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Customer10: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Customer10 {
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
