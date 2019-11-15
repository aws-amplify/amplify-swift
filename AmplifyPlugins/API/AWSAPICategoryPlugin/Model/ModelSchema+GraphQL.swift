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
    var graphqlName: String {
        targetName ?? name
    }

    /// The list of fields formatted for GraphQL usage.
    var graphqlFields: [String] {
        sortedFields.map { field in
            field.graphqlName
        }
    }
}

/// Extension that adds GraphQL specific utilities to `ModelField`.
extension ModelField {

    /// The GraphQL name of the field.
    var graphqlName: String {
        // TODO handle connected field name
        return targetName ?? name
    }
}
