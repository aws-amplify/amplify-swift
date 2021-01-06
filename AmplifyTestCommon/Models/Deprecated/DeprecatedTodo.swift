//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation
/*
The schema used to codegen this model:
 type DeprecatedTodo @model {
   id: ID!
   description: String
   note: Note
 }
 type Note {
   name: String!
   color: String!
 }

 Amplify CLI version used is less than 4.21.4. `.customType` has since been replaced with `.embedded(type)` and
 `.embeddedCollection(of)`. Please use Amplify CLI 4.21.4 or newer to re-generate your Models to conform to
 Embeddable type.
 */

public struct DeprecatedTodo: Model {
  public let id: String
  public var description: String?
  public var note: Note?

  public init(id: String = UUID().uuidString,
      description: String? = nil,
      note: Note? = nil) {
      self.id = id
      self.description = description
      self.note = note
  }
}

extension DeprecatedTodo {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case description
    case note
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let deprecatedTodo = DeprecatedTodo.keys

    model.pluralName = "DeprecatedTodos"

    model.fields(
      .id(),
      .field(deprecatedTodo.description, is: .optional, ofType: .string),
      .field(deprecatedTodo.note, is: .optional, ofType: .customType(Note.self))
    )
    }
}

public struct Note: Codable {
    var name: String
    var color: String
}
