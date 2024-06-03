// swiftlint:disable all
import Amplify
import Foundation

extension Video2 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case privacySetting
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let video2 = Video2.keys
    
    model.authRules = [
      rule(allow: .public, provider: .apiKey, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Video2s"
    model.syncPluralName = "Video2s"
    
    model.attributes(
      .primaryKey(fields: [video2.id])
    )
    
    model.fields(
      .field(video2.id, is: .required, ofType: .string),
      .field(video2.privacySetting, is: .optional, ofType: .enum(type: PrivacySetting2.self)),
      .field(video2.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(video2.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Video2> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Video2: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Video2 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}