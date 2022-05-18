//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

public struct ModelCompositePkWithAssociation: Model {
    public let id: String
    public let dob: Temporal.DateTime
    public var name: String?
    public var associatedModel: ModelCompositePk?
    public var createdAt: Temporal.DateTime?
    public var updatedAt: Temporal.DateTime?
    private var modelCompositePkWithAssociationOwnerId: String?
    private var modelCompositePkWithAssociationOwnerDob: Temporal.DateTime?

    public init(id: String = UUID().uuidString,
      dob: Temporal.DateTime,
      name: String? = nil,
      associatedModel: ModelCompositePk?) {
        self.init(id: id,
                  dob: dob,
                  name: name,
                  associatedModel: associatedModel,
                  modelCompositePkWithAssociationOwnerId: associatedModel?.id,
                  modelCompositePkWithAssociationOwnerDob: associatedModel?.dob,
                  createdAt: nil,
                  updatedAt: nil)
    }
    internal init(id: String = UUID().uuidString,
                  dob: Temporal.DateTime,
                  name: String? = nil,
                  associatedModel: ModelCompositePk?,
                  modelCompositePkWithAssociationOwnerId: String?,
                  modelCompositePkWithAssociationOwnerDob: Temporal.DateTime?,
                  createdAt: Temporal.DateTime? = nil,
                  updatedAt: Temporal.DateTime? = nil) {
        self.id = id
        self.dob = dob
        self.name = name
        self.associatedModel = associatedModel
        self.modelCompositePkWithAssociationOwnerId = modelCompositePkWithAssociationOwnerId
        self.modelCompositePkWithAssociationOwnerDob = modelCompositePkWithAssociationOwnerDob
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
