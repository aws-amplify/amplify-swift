// swiftlint:disable all
import Amplify
import Foundation

extension ListStringContainer {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case test
    case nullableString
    case stringList
    case stringNullableList
    case nullableStringList
    case nullableStringNullableList
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let listStringContainer = ListStringContainer.keys
    
    model.pluralName = "ListStringContainers"
    
    model.attributes(
      .primaryKey(fields: [listStringContainer.id])
    )
    
    model.fields(
      .field(listStringContainer.id, is: .required, ofType: .string),
      .field(listStringContainer.test, is: .required, ofType: .string),
      .field(listStringContainer.nullableString, is: .optional, ofType: .string),
      .field(listStringContainer.stringList, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.stringNullableList, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.nullableStringList, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.nullableStringNullableList, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(listStringContainer.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(listStringContainer.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<ListStringContainer> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension ListStringContainer: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == ListStringContainer {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var test: FieldPath<String>   {
      string("test") 
    }
  public var nullableString: FieldPath<String>   {
      string("nullableString") 
    }
  public var stringList: FieldPath<String>   {
      string("stringList") 
    }
  public var stringNullableList: FieldPath<String>   {
      string("stringNullableList") 
    }
  public var nullableStringList: FieldPath<String>   {
      string("nullableStringList") 
    }
  public var nullableStringNullableList: FieldPath<String>   {
      string("nullableStringNullableList") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}