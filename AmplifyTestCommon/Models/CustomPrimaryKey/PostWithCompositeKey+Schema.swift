// swiftlint:disable all
import Amplify
import Foundation

extension PostWithCompositeKey {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case comments
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post21 = PostWithCompositeKey.keys
    
    model.pluralName = "Post21s"
    
    model.attributes(
      .index(fields: ["id", "title"], name: nil),
      .primaryKey(fields: ["id", "title"])
    )
    
    model.fields(
      .field(post21.id, is: .required, ofType: .string),
      .field(post21.title, is: .required, ofType: .string),
      .hasMany(post21.comments, is: .optional, ofType: CommentWithCompositeKey.self, associatedWith: CommentWithCompositeKey.keys.post21CommentsId),
      .field(post21.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post21.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension PostWithCompositeKey: ModelIdentifiable {
    public typealias IdentifierFormat = ModelIdentifierFormat.Custom
    public typealias Identifier = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension PostWithCompositeKey.Identifier {
    static func identifier(id: String, title: String) -> Self {
        .make(fields: [(name: "id", value: id), (name: "title", value: title)])
    }
}
