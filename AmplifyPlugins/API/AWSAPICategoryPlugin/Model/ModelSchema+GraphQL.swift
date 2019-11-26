//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Extension that adds GraphQL specific utilities to `ModelSchema`.
extension ModelSchema {

    /// The GraphQL name of the schema.
    var graphQLName: String {
        targetName ?? name
    }

    /// The list of fields formatted for GraphQL usage.
    var graphQLFields: [ModelField] {
        sortedFields.filter { field in
            !field.hasAssociation || field.isAssociationOwner
        }
    }

    func findConnectedField(byType type: Model.Type) -> ModelField? {
        let fields = sortedFields.filter { field in
            field.hasAssociation && type == field.associatedModel
        }
        if fields.count > 1 {
            // TODO add a validation message. Check with CLI, they do the same validation
            preconditionFailure("")
        }
        return fields.first
    }

}

/// Extension that adds GraphQL specific utilities to `ModelField`.
extension ModelField {

    /// The GraphQL name of the field.
    var graphQLName: String {
        let name = targetName ?? self.name
        if isAssociationOwner {
            // TODO generate the correct connected field name
            // e.g. Post - Comment: `commentPostId` on the `Comment.post`
            return name + "Id"
        }
        return name
    }
}
