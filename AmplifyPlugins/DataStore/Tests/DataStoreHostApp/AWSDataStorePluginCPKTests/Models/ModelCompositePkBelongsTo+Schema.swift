//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension ModelCompositePkBelongsTo {
  // MARK: - CodingKeys
   public enum CodingKeys: String, ModelKey {
    case id
    case dob
    case owner
    case name
    case createdAt
    case updatedAt
  }

  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema

  public static let schema = defineSchema { model in
    let modelCompositePkBelongsTo = ModelCompositePkBelongsTo.keys

    model.pluralName = "ModelCompositePkBelongsTos"

    model.attributes(
      .index(fields: ["id", "dob"], name: nil)
    )

    model.fields(
        .field(modelCompositePkBelongsTo.id, is: .required, ofType: .string),
        .field(modelCompositePkBelongsTo.dob, is: .required, ofType: .dateTime),
        .field(modelCompositePkBelongsTo.name, is: .optional, ofType: .string),
        .belongsTo(modelCompositePkBelongsTo.owner, is: .optional,
                   ofType: ModelCompositePkWithAssociation.self,
                   targetNames: [
                    "modelCompositePkWithAssociationOtherModelsId",
                    "modelCompositePkWithAssociationOtherModelsDob"
                   ]),
        .field(modelCompositePkBelongsTo.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
        .field(modelCompositePkBelongsTo.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension ModelCompositePkBelongsTo: ModelIdentifiable {
    public typealias IdentifierFormat = ModelIdentifierFormat.Custom
    public typealias Identifier = ModelIdentifier<Self, ModelIdentifierFormat.Custom>
}

extension ModelCompositePkBelongsTo.Identifier {
    public static func identifier(id: String, dob: Temporal.DateTime) -> Self {
        .make(fields: [(name: "id", value: id), (name: "dob", value: dob)])
    }
}
