// swiftlint:disable all
import Amplify
import Foundation

extension ScalarContainer {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case myString
    case myInt
    case myDouble
    case myBool
    case myDate
    case myTime
    case myDateTime
    case myTimeStamp
    case myEmail
    case myJSON
    case myPhone
    case myURL
    case myIPAddress
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let scalarContainer = ScalarContainer.keys
    
    model.pluralName = "ScalarContainers"
    
    model.attributes(
      .primaryKey(fields: [scalarContainer.id])
    )
    
    model.fields(
      .field(scalarContainer.id, is: .required, ofType: .string),
      .field(scalarContainer.myString, is: .optional, ofType: .string),
      .field(scalarContainer.myInt, is: .optional, ofType: .int),
      .field(scalarContainer.myDouble, is: .optional, ofType: .double),
      .field(scalarContainer.myBool, is: .optional, ofType: .bool),
      .field(scalarContainer.myDate, is: .optional, ofType: .date),
      .field(scalarContainer.myTime, is: .optional, ofType: .time),
      .field(scalarContainer.myDateTime, is: .optional, ofType: .dateTime),
      .field(scalarContainer.myTimeStamp, is: .optional, ofType: .int),
      .field(scalarContainer.myEmail, is: .optional, ofType: .string),
      .field(scalarContainer.myJSON, is: .optional, ofType: .string),
      .field(scalarContainer.myPhone, is: .optional, ofType: .string),
      .field(scalarContainer.myURL, is: .optional, ofType: .string),
      .field(scalarContainer.myIPAddress, is: .optional, ofType: .string),
      .field(scalarContainer.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(scalarContainer.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<ScalarContainer> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension ScalarContainer: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == ScalarContainer {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var myString: FieldPath<String>   {
      string("myString") 
    }
  public var myInt: FieldPath<Int>   {
      int("myInt") 
    }
  public var myDouble: FieldPath<Double>   {
      double("myDouble") 
    }
  public var myBool: FieldPath<Bool>   {
      bool("myBool") 
    }
  public var myDate: FieldPath<Temporal.Date>   {
      date("myDate") 
    }
  public var myTime: FieldPath<Temporal.Time>   {
      time("myTime") 
    }
  public var myDateTime: FieldPath<Temporal.DateTime>   {
      datetime("myDateTime") 
    }
  public var myTimeStamp: FieldPath<Int>   {
      int("myTimeStamp") 
    }
  public var myEmail: FieldPath<String>   {
      string("myEmail") 
    }
  public var myJSON: FieldPath<String>   {
      string("myJSON") 
    }
  public var myPhone: FieldPath<String>   {
      string("myPhone") 
    }
  public var myURL: FieldPath<String>   {
      string("myURL") 
    }
  public var myIPAddress: FieldPath<String>   {
      string("myIPAddress") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}