// swiftlint:disable all
import Amplify
import Foundation

extension Post11 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case content
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post11 = Post11.keys
    
    model.authRules = [
      rule(allow: .public, provider: .iam, operations: [.read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Post11s"
    model.syncPluralName = "Post11s"
    
    model.attributes(
      .primaryKey(fields: [post11.id])
    )
    
    model.fields(
      .field(post11.id, is: .required, ofType: .string),
      .field(post11.title, is: .optional, ofType: .string),
      .field(post11.content, is: .optional, ofType: .string),
      .field(post11.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post11.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Post11> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Post11: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Post11 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var title: FieldPath<String>   {
      string("title") 
    }
  public var content: FieldPath<String>   {
      string("content") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}