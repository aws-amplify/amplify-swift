// swiftlint:disable all
import Amplify
import Foundation

extension Blog8V2 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case customs
    case notes
    case posts
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let blog8V2 = Blog8V2.keys
    
    model.pluralName = "Blog8V2s"
    
    model.attributes(
      .primaryKey(fields: [blog8V2.id])
    )
    
    model.fields(
      .field(blog8V2.id, is: .required, ofType: .string),
      .field(blog8V2.name, is: .required, ofType: .string),
      .field(blog8V2.customs, is: .optional, ofType: .embeddedCollection(of: MyCustomModel8.self)),
      .field(blog8V2.notes, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .hasMany(blog8V2.posts, is: .optional, ofType: Post8V2.self, associatedWith: Post8V2.keys.blog),
      .field(blog8V2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(blog8V2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Blog8V2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}