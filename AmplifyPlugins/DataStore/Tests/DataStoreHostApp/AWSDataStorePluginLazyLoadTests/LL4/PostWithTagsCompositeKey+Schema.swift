// swiftlint:disable all
import Amplify
import Foundation

extension PostWithTagsCompositeKey {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case postId
    case title
    case tags
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let postWithTagsCompositeKey = PostWithTagsCompositeKey.keys
    
    model.pluralName = "PostWithTagsCompositeKeys"
    
    model.attributes(
      .index(fields: ["postId", "title"], name: nil),
      .primaryKey(fields: [postWithTagsCompositeKey.postId, postWithTagsCompositeKey.title])
    )
    
    model.fields(
      .field(postWithTagsCompositeKey.postId, is: .required, ofType: .string),
      .field(postWithTagsCompositeKey.title, is: .required, ofType: .string),
      .hasMany(postWithTagsCompositeKey.tags, is: .optional, ofType: PostTagsWithCompositeKey.self, associatedWith: PostTagsWithCompositeKey.keys.postWithTagsCompositeKey),
      .field(postWithTagsCompositeKey.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(postWithTagsCompositeKey.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<PostWithTagsCompositeKey> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension PostWithTagsCompositeKey: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Custom
  public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension PostWithTagsCompositeKey.IdentifierProtocol {
  public static func identifier(postId: String,
      title: String) -> Self {
    .make(fields:[(name: "postId", value: postId), (name: "title", value: title)])
  }
}
extension ModelPath where ModelType == PostWithTagsCompositeKey {
  public var postId: FieldPath<String>   {
      string("postId")
    }
  public var title: FieldPath<String>   {
      string("title")
    }
  public var tags: ModelPath<PostTagsWithCompositeKey>   {
      PostTagsWithCompositeKey.Path(name: "tags", isCollection: true, parent: self)
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
