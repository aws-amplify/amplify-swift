//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
@preconcurrency import Amplify
import Foundation

public extension Todo {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case name
    case description
    case categories
    case section
    case stickies
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let todo = Todo.keys

    model.listPluralName = "Todos"
    model.syncPluralName = "Todos"

    model.fields(
      .id(),
      .field(todo.name, is: .required, ofType: .string),
      .field(todo.description, is: .optional, ofType: .string),
      .field(todo.categories, is: .optional, ofType: .embeddedCollection(of: Category.self)),
      .field(todo.section, is: .optional, ofType: .embedded(type: Section.self)),
      .field(todo.stickies, is: .optional, ofType: .embeddedCollection(of: String.self))
    )
    }
}
