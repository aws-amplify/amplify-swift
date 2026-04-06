//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension MutationEvent {
    // MARK: - CodingKeys

    enum CodingKeys: String, ModelKey {
        case id
        case modelId
        case modelName
        case json
        case mutationType
        case createdAt
        case version
        case inProcess
        case graphQLFilterJSON
    }

    static let keys = CodingKeys.self

    // MARK: - ModelSchema

    nonisolated(unsafe) static let schema = defineSchema { definition in
        let mutation = MutationEvent.keys

        definition.listPluralName = "MutationEvents"
        definition.syncPluralName = "MutationEvents"
        definition.attributes(.isSystem)

        definition.fields(
            .id(),
            .field(mutation.modelId, is: .required, ofType: .string),
            .field(mutation.modelName, is: .required, ofType: .string),
            .field(mutation.json, is: .required, ofType: .string),
            .field(mutation.mutationType, is: .required, ofType: .string),
            .field(mutation.createdAt, is: .required, ofType: .dateTime),
            .field(mutation.version, is: .optional, ofType: .int),
            .field(mutation.inProcess, is: .required, ofType: .bool),
            .field(mutation.graphQLFilterJSON, is: .optional, ofType: .string)
        )
    }
}
