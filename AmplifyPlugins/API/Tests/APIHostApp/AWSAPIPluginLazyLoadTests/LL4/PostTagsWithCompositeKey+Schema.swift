//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public extension PostTagsWithCompositeKey {
  // MARK: - CodingKeys
   enum CodingKeys: String, ModelKey {
    case id
    case postWithTagsCompositeKey
    case tagWithCompositeKey
    case createdAt
    case updatedAt
  }

  static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  static let schema = defineSchema { model in
    let postTagsWithCompositeKey = PostTagsWithCompositeKey.keys

    model.pluralName = "PostTagsWithCompositeKeys"

    model.attributes(
      .index(fields: ["postWithTagsCompositeKeyPostId", "postWithTagsCompositeKeytitle"], name: "byPostWithTagsCompositeKey"),
      .index(fields: ["tagWithCompositeKeyId", "tagWithCompositeKeyname"], name: "byTagWithCompositeKey"),
      .primaryKey(fields: [postTagsWithCompositeKey.id])
    )

    model.fields(
      .field(postTagsWithCompositeKey.id, is: .required, ofType: .string),
      .belongsTo(postTagsWithCompositeKey.postWithTagsCompositeKey, is: .required, ofType: PostWithTagsCompositeKey.self, targetNames: ["postWithTagsCompositeKeyPostId", "postWithTagsCompositeKeytitle"]),
      .belongsTo(postTagsWithCompositeKey.tagWithCompositeKey, is: .required, ofType: TagWithCompositeKey.self, targetNames: ["tagWithCompositeKeyId", "tagWithCompositeKeyname"]),
      .field(postTagsWithCompositeKey.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(postTagsWithCompositeKey.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    class Path: ModelPath<PostTagsWithCompositeKey> { }

    static var rootPath: PropertyContainerPath? { Path() }
}

extension PostTagsWithCompositeKey: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
public extension ModelPath where ModelType == PostTagsWithCompositeKey {
  var id: FieldPath<String>   {
      string("id")
    }
  var postWithTagsCompositeKey: ModelPath<PostWithTagsCompositeKey>   {
      PostWithTagsCompositeKey.Path(name: "postWithTagsCompositeKey", parent: self)
    }
  var tagWithCompositeKey: ModelPath<TagWithCompositeKey>   {
      TagWithCompositeKey.Path(name: "tagWithCompositeKey", parent: self)
    }
  var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
