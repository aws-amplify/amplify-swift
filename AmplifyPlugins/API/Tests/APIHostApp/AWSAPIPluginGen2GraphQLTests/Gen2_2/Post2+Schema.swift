//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension Post2 {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case content
    case privacySetting
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let post2 = Post2.keys

    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Post2s"
    model.syncPluralName = "Post2s"

    model.attributes(
      .primaryKey(fields: [post2.id])
    )

    model.fields(
      .field(post2.id, is: .required, ofType: .string),
      .field(post2.content, is: .optional, ofType: .string),
      .field(post2.privacySetting, is: .optional, ofType: .enum(type: PrivacySetting2.self)),
      .field(post2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<Post2> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension Post2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == Post2 {
  var id: FieldPath<String>   {
      string("id")
    }
  var content: FieldPath<String>   {
      string("content")
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
