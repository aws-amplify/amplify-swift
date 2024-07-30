// swiftlint:disable all
import Amplify
import Foundation

extension Todo15 {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case content
    case owners
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let todo15 = Todo15.keys

    model.authRules = [
      rule(allow: .owner, ownerField: "owners", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]

    model.listPluralName = "Todo15s"
    model.syncPluralName = "Todo15s"

    model.attributes(
      .primaryKey(fields: [todo15.id])
    )

    model.fields(
      .field(todo15.id, is: .required, ofType: .string),
      .field(todo15.content, is: .optional, ofType: .string),
      .field(todo15.owners, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(todo15.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todo15.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Todo15> { }

    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Todo15: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Todo15 {
  public var id: FieldPath<String>   {
      string("id")
    }
  public var content: FieldPath<String>   {
      string("content")
    }
  public var owners: FieldPath<String>   {
      string("owners")
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt")
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt")
    }
}
