//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension ListStringContainer {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case test
    case nullableString
    case stringList
    case stringNullableList
    case nullableStringList
    case nullableStringNullableList
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let listStringContainer = ListStringContainer.keys

    model.pluralName = "ListStringContainers"

    model.attributes(
      .primaryKey(fields: [listStringContainer.id])
    )

    model.fields(
      .field(listStringContainer.id, is: .required, ofType: .string),
      .field(listStringContainer.test, is: .required, ofType: .string),
      .field(listStringContainer.nullableString, is: .optional, ofType: .string),
      .field(listStringContainer.stringList, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.stringNullableList, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.nullableStringList, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.nullableStringNullableList, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(listStringContainer.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<ListStringContainer> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension ListStringContainer: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == ListStringContainer {
  var id: FieldPath<String>   {
      string("id")
    }
  var test: FieldPath<String>   {
      string("test")
    }
  var nullableString: FieldPath<String>   {
      string("nullableString")
    }
  var stringList: FieldPath<String>   {
      string("stringList")
    }
  var stringNullableList: FieldPath<String>   {
      string("stringNullableList")
    }
  var nullableStringList: FieldPath<String>   {
      string("nullableStringList")
    }
  var nullableStringNullableList: FieldPath<String>   {
      string("nullableStringNullableList")
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
