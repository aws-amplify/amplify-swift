// swiftlint:disable all
import Amplify
import Foundation

extension ListIntContainer {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case test
    case nullableInt
    case intList
    case intNullableList
    case nullableIntList
    case nullableIntNullableList
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let listIntContainer = ListIntContainer.keys
    
    model.pluralName = "ListIntContainers"
    
    model.attributes(
      .primaryKey(fields: [listIntContainer.id])
    )
    
    model.fields(
      .field(listIntContainer.id, is: .required, ofType: .string),
      .field(listIntContainer.test, is: .required, ofType: .int),
      .field(listIntContainer.nullableInt, is: .optional, ofType: .int),
      .field(listIntContainer.intList, is: .required, ofType: .embeddedCollection(of: Int.self)),
      .field(listIntContainer.intNullableList, is: .optional, ofType: .embeddedCollection(of: Int.self)),
      .field(listIntContainer.nullableIntList, is: .required, ofType: .embeddedCollection(of: Int.self)),
      .field(listIntContainer.nullableIntNullableList, is: .optional, ofType: .embeddedCollection(of: Int.self)),
      .field(listIntContainer.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(listIntContainer.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<ListIntContainer> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension ListIntContainer: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == ListIntContainer {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var test: FieldPath<Int>   {
      int("test") 
    }
  public var nullableInt: FieldPath<Int>   {
      int("nullableInt") 
    }
  public var intList: FieldPath<Int>   {
      int("intList") 
    }
  public var intNullableList: FieldPath<Int>   {
      int("intNullableList") 
    }
  public var nullableIntList: FieldPath<Int>   {
      int("nullableIntList") 
    }
  public var nullableIntNullableList: FieldPath<Int>   {
      int("nullableIntNullableList") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}