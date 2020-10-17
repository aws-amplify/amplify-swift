//
// Copyright 2018-2020 Amazon.com,
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

            // TODO how to handle associations of type "many" (i.e. cascade save)?
            // This is not supported right now and might be added as a future feature
            if case .collection = field.type {
                return
            }

            let name = field.graphQLName
            let fieldValue = self[field.name] ?? nil

            // swiftlint:disable:next syntactic_sugar
            guard case .some(Optional<Any>.some(let value)) = fieldValue else {
                input.updateValue(nil, forKey: name)
                return
            }

            switch field.type {
            case .date, .dateTime, .time:
                if let date = value as? TemporalSpec {
                    input[name] = date.iso8601String
                } else {
                    input[name] = value
                }
            case .enum:
                input[name] = (value as? EnumPersistable)?.rawValue
            case .model:
                // For Models, append the model name in front in case a targetName is not provided
                // e.g. "comment" + "PostId"
                var fieldName = modelName.camelCased() + name
                if case let .belongsTo(_, targetName) = field.association {
                    fieldName = targetName ?? fieldName
                }
                input[fieldName] = (value as? Model)?.id
            case .embedded, .embeddedCollection:
                if let encodable = value as? Encodable {
                    let jsonEncoder = JSONEncoder(dateEncodingStrategy: ModelDateFormatting.encodingStrategy)
                    do {
                        let data = try jsonEncoder.encode(encodable.eraseToAnyEncodable())
                        input[name] = try JSONSerialization.jsonObject(with: data)
                    } catch {
                        preconditionFailure("Could not turn into json object from \(value)")
                    }
                }
            default:
                input[name] = value
            }
        }
        return input
    }
}
