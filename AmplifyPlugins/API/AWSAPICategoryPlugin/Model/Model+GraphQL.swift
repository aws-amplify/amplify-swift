//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

typealias GraphQLInput = [String: Any?]

/// Extension that adds GraphQL specific utilities to concret types of `Model`.
extension Model {

    /// Get the `Model` values as a `Dictionary` of `String` to `Any?` that can be
    /// used as the `input` of GraphQL related operations.
    var graphQLInput: GraphQLInput {
        let modelType = type(of: self)
        let schema = modelType.schema

        var input: GraphQLInput = [:]
        schema.fields.forEach {
            let field = $0.value
            let name = field.graphQLName
            let value = self[field.name]

            // TODO handle relationships (connected properties)
            input[name] = value
        }
        return input
    }
}
