// swiftlint:disable all
import Amplify
import Foundation

extension User14 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case username
    case posts
    case comments
    case settings
    case createdAt
    case updatedAt
    case user14SettingsId
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let user14 = User14.keys
    
    model.authRules = [
      rule(allow: .public, operations: [.create, .update, .delete, .read])
    ]
    
    model.pluralName = "User14s"
    
    model.attributes(
      .primaryKey(fields: [user14.id])
    )
    
    model.fields(
      .field(user14.id, is: .required, ofType: .string),
      .field(user14.username, is: .required, ofType: .string),
      .hasMany(user14.posts, is: .optional, ofType: Post14.self, associatedWith: Post14.keys.author),
      .hasMany(user14.comments, is: .optional, ofType: Comment14.self, associatedWith: Comment14.keys.author),
      .hasOne(user14.settings, is: .optional, ofType: UserSettings14.self, associatedWith: UserSettings14.keys.user, targetNames: ["user14SettingsId"]),
      .field(user14.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(user14.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(user14.user14SettingsId, is: .optional, ofType: .string)
    )
    }
    public class Path: ModelPath<User14> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension User14: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == User14 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var username: FieldPath<String>   {
      string("username") 
    }
  public var posts: ModelPath<Post14>   {
      Post14.Path(name: "posts", isCollection: true, parent: self) 
    }
  public var comments: ModelPath<Comment14>   {
      Comment14.Path(name: "comments", isCollection: true, parent: self) 
    }
  public var settings: ModelPath<UserSettings14>   {
      UserSettings14.Path(name: "settings", parent: self) 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
  public var user14SettingsId: FieldPath<String>   {
      string("user14SettingsId") 
    }
}