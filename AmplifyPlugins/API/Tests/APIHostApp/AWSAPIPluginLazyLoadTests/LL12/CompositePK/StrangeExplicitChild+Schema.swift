//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension StrangeExplicitChild {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case strangeId
    case content
    case parent
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let strangeExplicitChild = StrangeExplicitChild.keys

    model.pluralName = "StrangeExplicitChildren"

    model.attributes(
      .index(fields: ["strangeId", "content"], name: nil),
      .index(fields: ["strangeParentId", "strangeParentTitle"], name: "byCompositePKParentX"),
      .primaryKey(fields: [strangeExplicitChild.strangeId, strangeExplicitChild.content])
    )

    model.fields(
      .field(strangeExplicitChild.strangeId, is: .required, ofType: .string),
      .field(strangeExplicitChild.content, is: .required, ofType: .string),
      .belongsTo(strangeExplicitChild.parent, is: .required, ofType: CompositePKParent.self, targetNames: ["strangeParentId", "strangeParentTitle"]),
      .field(strangeExplicitChild.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(strangeExplicitChild.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<StrangeExplicitChild> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension StrangeExplicitChild: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

public extension StrangeExplicitChild.IdentifierProtocol {
  static func identifier(
    strangeId: String,
    content: String
  ) -> Self {
    .make(fields: [(name: "strangeId", value: strangeId), (name: "content", value: content)])
  }
}
public extension ModelPath where ModelType == StrangeExplicitChild {
  var strangeId: FieldPath<String>   {
      string("strangeId")
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
