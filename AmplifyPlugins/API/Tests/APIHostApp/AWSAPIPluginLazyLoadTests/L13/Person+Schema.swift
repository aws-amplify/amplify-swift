//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Person {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case callerOf
    case calleeOf
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let person = Person.keys

    model.pluralName = "People"

    model.attributes(
      .primaryKey(fields: [person.id])
    )

    model.fields(
      .field(person.id, is: .required, ofType: .string),
      .field(person.name, is: .required, ofType: .string),
      .hasMany(person.callerOf, is: .optional, ofType: PhoneCall.self, associatedWith: PhoneCall.keys.caller),
      // TODO: Below `associatedWith` was incorrectly generated as `PhoneCall.keys.caller`, it was manually
      // modified to `PhoneCall.keys.caller`
      .hasMany(person.calleeOf, is: .optional, ofType: PhoneCall.self, associatedWith: PhoneCall.keys.callee),
      .field(person.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(person.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Person> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Person: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Person {
  var id: FieldPath<String>   {
      string("id")
    }
  var name: FieldPath<String>   {
      string("name")
    }
  var callerOf: ModelPath<PhoneCall>   {
      PhoneCall.Path(name: "callerOf", isCollection: true, parent: self)
    }
  var calleeOf: ModelPath<PhoneCall>   {
      PhoneCall.Path(name: "calleeOf", isCollection: true, parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
