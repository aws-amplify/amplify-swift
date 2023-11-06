//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension TodoCognitoPrivate {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case title
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema
  
  public static let schema = defineSchema { model in
    let todoCognitoPrivate = TodoCognitoPrivate.keys
    
    model.authRules = [
      rule(allow: .private, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "TodoCognitoPrivates"
    model.syncPluralName = "TodoCognitoPrivates"
    
    model.attributes(
      .primaryKey(fields: [todoCognitoPrivate.id])
    )
    
    model.fields(
      .field(todoCognitoPrivate.id, is: .required, ofType: .string),
      .field(todoCognitoPrivate.title, is: .required, ofType: .string),
      .field(todoCognitoPrivate.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(todoCognitoPrivate.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension TodoCognitoPrivate: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
