//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension ImplicitChild {
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
    let implicitChild = ImplicitChild.keys

    model.pluralName = "ImplicitChildren"

    model.attributes(
      .index(fields: ["childId", "content"], name: nil),
      .primaryKey(fields: [implicitChild.childId, implicitChild.content])
    )

    model.fields(
      .field(implicitChild.childId, is: .required, ofType: .string),
      .field(implicitChild.content, is: .required, ofType: .string),
      .belongsTo(implicitChild.parent, is: .required, ofType: CompositePKParent.self, targetNames: ["compositePKParentImplicitChildrenCustomId", "compositePKParentImplicitChildrenContent"]),
      .field(implicitChild.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(implicitChild.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<ImplicitChild> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension ImplicitChild: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension ImplicitChild.IdentifierProtocol {
  static func identifier(
    childId: String,
    content: String
  ) -> Self {
    .make(fields: [(name: "childId", value: childId), (name: "content", value: content)])
  }
}
public extension ModelPath where ModelType == ImplicitChild {
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
