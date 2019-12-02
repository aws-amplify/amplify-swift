//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias GraphQLInput = [String: Any?]

/// Extension that adds GraphQL specific utilities to concret types of `Model`.
extension Model {

    /// Get the `Model` values as a `Dictionary` of `String` to `Any?` that can be
    /// used as the `input` of GraphQL related operations.
    var graphQLInput: GraphQLInput {
        var input: GraphQLInput = [:]
        schema.fields.forEach {
            let field = $0.value
            let name = field.graphQLName
            let value = self[field.name]

            switch field.typeDefinition {
            case .date, .dateTime:
                if let date = value as? Date {
                    input[name] = date.iso8601String
                } else {
                    input[name] = value
                }
            case .model:
                // For Models, append the model name in front in case a targetName is not provided
                // e.g. "comment" + "PostId"
                var fieldName = modelName.camelCased() + name
                if case let .belongsTo(_, targetName) = field.association {
                    fieldName = targetName ?? fieldName
                }
                input[fieldName] = (value as? Model)?.id
            case .collection:
                // TODO how to handle associations of type "many" (i.e. cascade save)?
                break
            default:
                input[name] = value
            }
        }
        return input
    }
}
