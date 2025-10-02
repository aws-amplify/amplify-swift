//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension CompositePKChild {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case childId
    case content
    case parent
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let compositePKChild = CompositePKChild.keys

    model.pluralName = "CompositePKChildren"

    model.attributes(
      .index(fields: ["childId", "content"], name: nil),
      .index(fields: ["parentId", "parentTitle"], name: "byParent"),
      .primaryKey(fields: [compositePKChild.childId, compositePKChild.content])
    )

    model.fields(
      .field(compositePKChild.childId, is: .required, ofType: .string),
      .field(compositePKChild.content, is: .required, ofType: .string),
      .belongsTo(compositePKChild.parent, is: .optional, ofType: CompositePKParent.self, targetNames: ["parentId", "parentTitle"]),
      .field(compositePKChild.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(compositePKChild.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<CompositePKChild> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension CompositePKChild: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension CompositePKChild.IdentifierProtocol {
  static func identifier(
    childId: String,
    content: String
  ) -> Self {
    .make(fields: [(name: "childId", value: childId), (name: "content", value: content)])
  }
}
public extension ModelPath where ModelType == CompositePKChild {
  var childId: FieldPath<String>   {
      string("childId")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var parent: ModelPath<CompositePKParent>   {
      CompositePKParent.Path(name: "parent", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
