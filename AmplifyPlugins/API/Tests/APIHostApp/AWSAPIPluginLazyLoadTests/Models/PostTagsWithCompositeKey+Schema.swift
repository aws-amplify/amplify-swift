// swiftlint:disable all
import Amplify
import Foundation

extension PostTagsWithCompositeKey {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case postWithTagsCompositeKey
    case tagWithCompositeKey
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
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
}

extension PostTagsWithCompositeKey: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}