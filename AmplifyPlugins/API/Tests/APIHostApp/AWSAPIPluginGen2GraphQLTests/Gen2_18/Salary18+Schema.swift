// swiftlint:disable all
import Amplify
import Foundation

extension Salary18 {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case wage
    case currency
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let salary18 = Salary18.keys
    
    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Admin"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Salary18s"
    model.syncPluralName = "Salary18s"
    
    model.attributes(
      .primaryKey(fields: [salary18.id])
    )
    
    model.fields(
      .field(salary18.id, is: .required, ofType: .string),
      .field(salary18.wage, is: .optional, ofType: .double),
      .field(salary18.currency, is: .optional, ofType: .string),
      .field(salary18.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(salary18.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Salary18> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Salary18: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Salary18 {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var wage: FieldPath<Double>   {
      double("wage") 
    }
  public var currency: FieldPath<String>   {
      string("currency") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}