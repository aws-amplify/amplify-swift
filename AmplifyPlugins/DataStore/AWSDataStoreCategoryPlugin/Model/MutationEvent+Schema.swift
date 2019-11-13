//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension MutationEvent {
    // MARK: - CodingKeys

    public enum CodingKeys: String, ModelKey {
        case id
        case modelName
        case data
        case type
        case source
        case predicate
        case createdAt
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let mutation = MutationEvent.keys

        model.syncable = false
        // TODO how to make this non-acessible to developers?
//        model.namespace = .system

        model.fields(
            .id(),
            .field(mutation.modelName, is: .required, ofType: .string),
            .field(mutation.data, is: .required, ofType: .string),
            .field(mutation.type, is: .required, ofType: .enum(MutationEventType.self)),
            .field(mutation.source, is: .required, ofType: .enum(MutationEventSource.self)),
            .field(mutation.predicate, is: .optional, ofType: .string),
            .field(mutation.createdAt, is: .required, ofType: .dateTime)
        )
    }
}
