// swiftlint:disable all
import Amplify
import Foundation

extension CommentWithCompositeKey {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case createdAt
    case updatedAt
    case post21CommentsId
    case post21CommentsTitle
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let comment21 = CommentWithCompositeKey.keys
    
    model.pluralName = "Comment21s"
    
    model.attributes(
      .index(fields: ["id", "content"], name: nil),
      .primaryKey(fields: ["id", "content"])
    )
    
    model.fields(
      .field(comment21.id, is: .required, ofType: .string),
      .field(comment21.content, is: .required, ofType: .string),
      .field(comment21.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment21.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(comment21.post21CommentsId, is: .optional, ofType: .string),
      .field(comment21.post21CommentsTitle, is: .optional, ofType: .string)
    )
    }
}

extension CommentWithCompositeKey: ModelIdentifiable {
    public typealias IdentifierFormat = ModelIdentifierFormat.Custom
    public typealias Identifier = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension CommentWithCompositeKey.Identifier {
    static func identifier(id: String, content: String) -> Self {
        .make(fields: [(name: "id", value: id), (name: "content", value: content)])
    }
}

