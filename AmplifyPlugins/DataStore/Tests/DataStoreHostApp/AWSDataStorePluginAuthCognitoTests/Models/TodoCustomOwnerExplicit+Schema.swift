//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension TodoCustomOwnerExplicit {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case dominus
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let todoCustomOwnerExplicit = TodoCustomOwnerExplicit.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "dominus", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "TodoCustomOwnerExplicits"
    model.syncPluralName = "TodoCustomOwnerExplicits"
    
    model.attributes(
      .primaryKey(fields: [todoCustomOwnerExplicit.id])
    )
    
    model.fields(
      .field(todoCustomOwnerExplicit.id, is: .required, ofType: .string),
      .field(todoCustomOwnerExplicit.title, is: .required, ofType: .string),
      .field(todoCustomOwnerExplicit.dominus, is: .optional, ofType: .string),
      .field(todoCustomOwnerExplicit.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoCustomOwnerExplicit.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension TodoCustomOwnerExplicit: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
