//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

enum ModelRelationship {
    case manyToMany(Model.Type)
    case manyToOne(Model.Type)
    case oneToMany(Model.Type)
    case oneToOne(Model.Type, name: String)
}

/// Extension that adds GraphQL specific utilities to `ModelSchema`.
extension ModelSchema {

    /// The GraphQL name of the schema.
    var graphQLName: String {
        targetName ?? name
    }

    /// The list of fields formatted for GraphQL usage.
    var graphQLFields: [String] {
        sortedFields.map { field in
            field.graphQLName
        }
    }
}

/// Extension that adds GraphQL specific utilities to `ModelField`.
extension ModelField {

    /// The GraphQL name of the field.
    var graphQLName: String {
        // TODO handle connected field name
        return targetName ?? name
    }
}
