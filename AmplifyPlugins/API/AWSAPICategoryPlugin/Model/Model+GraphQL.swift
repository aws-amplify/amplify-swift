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
        var input: GraphQLInput = [:]
        schema.fields.forEach {
            let field = $0.value
            let name = field.graphQLName
            let value = self[field.name]

            switch field.typeDefinition {
            case .date, .dateTime:
                if let date = value as? Date {
                    input[name] = date.iso8601
                } else {
                    input[name] = value
                }
            case .collection(let of):
                // TODO handle relationships (connected properties)
                break
            default:
                input[name] = value
            }
        }
        return input
    }
}
