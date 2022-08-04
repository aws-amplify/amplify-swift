//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Todo {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case description
    case categories
    case section
    case stickies
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
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
