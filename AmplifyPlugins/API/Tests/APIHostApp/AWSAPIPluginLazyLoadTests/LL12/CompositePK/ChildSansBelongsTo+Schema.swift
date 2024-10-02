//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension ChildSansBelongsTo {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case childId
    case content
    case compositePKParentChildrenSansBelongsToCustomId
    case compositePKParentChildrenSansBelongsToContent
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let childSansBelongsTo = ChildSansBelongsTo.keys

    model.pluralName = "ChildSansBelongsTos"

    model.attributes(
      .index(fields: ["childId", "content"], name: nil),
      .index(fields: ["compositePKParentChildrenSansBelongsToCustomId", "compositePKParentChildrenSansBelongsToContent"], name: "byParent"),
      .primaryKey(fields: [childSansBelongsTo.childId, childSansBelongsTo.content])
    )

    model.fields(
      .field(childSansBelongsTo.childId, is: .required, ofType: .string),
      .field(childSansBelongsTo.content, is: .required, ofType: .string),
      .field(childSansBelongsTo.compositePKParentChildrenSansBelongsToCustomId, is: .required, ofType: .string),
      .field(childSansBelongsTo.compositePKParentChildrenSansBelongsToContent, is: .optional, ofType: .string),
      .field(childSansBelongsTo.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(childSansBelongsTo.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<ChildSansBelongsTo> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension ChildSansBelongsTo: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension ChildSansBelongsTo.IdentifierProtocol {
  static func identifier(
    childId: String,
    content: String
  ) -> Self {
    .make(fields: [(name: "childId", value: childId), (name: "content", value: content)])
  }
}
public extension ModelPath where ModelType == ChildSansBelongsTo {
  var childId: FieldPath<String>   {
      string("childId")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var compositePKParentChildrenSansBelongsToCustomId: FieldPath<String>   {
      string("compositePKParentChildrenSansBelongsToCustomId")
    }
  var compositePKParentChildrenSansBelongsToContent: FieldPath<String>   {
      string("compositePKParentChildrenSansBelongsToContent")
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
