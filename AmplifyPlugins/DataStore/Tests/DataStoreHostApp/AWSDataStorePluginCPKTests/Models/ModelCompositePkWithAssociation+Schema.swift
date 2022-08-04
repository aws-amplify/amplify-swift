//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension ModelCompositePkWithAssociation {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case dob
    case name
    case otherModels
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let modelCompositePkWithAssociation = ModelCompositePkWithAssociation.keys

    model.pluralName = "ModelCompositePkWithAssociations"

    model.attributes(
        .index(fields: ["id", "dob"], name: nil)
    )

    model.fields(
        .field(modelCompositePkWithAssociation.id, is: .required, ofType: .string),
        .field(modelCompositePkWithAssociation.dob, is: .required, ofType: .dateTime),
        .field(modelCompositePkWithAssociation.name, is: .optional, ofType: .string),
        .hasMany(modelCompositePkWithAssociation.otherModels,
                 is: .optional,
                 ofType: ModelCompositePkBelongsTo.self,
                 associatedWith: ModelCompositePkBelongsTo.keys.owner),
        .field(modelCompositePkWithAssociation.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
        .field(modelCompositePkWithAssociation.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
  }
}

extension ModelCompositePkWithAssociation: ModelIdentifiable {
    public typealias IdentifierFormat = ModelIdentifierFormat.Custom
    public typealias IdentifierProtocol = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension ModelCompositePkWithAssociation.IdentifierProtocol {
    public static func identifier(id: String, dob: Temporal.DateTime) -> Self {
        .make(fields: [(name: "id", value: id), (name: "dob", value: dob)])
    }
}

