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
        name
    }

    /// The list of fields formatted for GraphQL usage.
    var graphQLFields: [ModelField] {
        sortedFields.filter { field in
            !field.hasAssociation || field.isAssociationOwner
        }
    }

}

/// Extension that adds GraphQL specific utilities to `ModelField`.
extension ModelField {

    /// The GraphQL name of the field.
    var graphQLName: String {
        if isAssociationOwner, case let .belongsTo(_, targetName) = association {
            return targetName ?? name.pascalCased() + "Id"
        }
        return name
    }
}
