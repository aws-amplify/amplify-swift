//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

enum MutationEventSource: String, Codable {
    case dataStore
    case syncEngine
    case storageEngine
}

enum MutationEventType: String, Codable {
    case save
    case delete
}

enum MutationEventStatus: String, Codable {
    case synced
    case pending
    case failed
}

internal struct MutationEvent: Model {

    internal let id: Identifier
    internal let modelName: String
    internal let data: String
    internal let type: MutationEventType
    internal let source: MutationEventSource
    internal let predicate: String?
    internal let createdAt: Date

    init(id: Identifier = UUID().uuidString,
         modelName: String,
         data: String,
         type: MutationEventType,
         source: MutationEventSource,
         predicate: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.modelName = modelName
        self.data = data
        self.type = type
        self.source = source
        self.predicate = predicate
        self.createdAt = createdAt
    }

    func getModel<M: Model>() throws -> M {
        let model = try M.from(json: data)
        return model
    }

}

// MARK: - Factory

extension MutationEvent {

    static func from<M: Model>(model: M,
                               type: MutationEventType,
                               source: MutationEventSource,
                               predicate: QueryPredicate? = nil) throws -> MutationEvent {
        let modelType = Swift.type(of: model)
        let data = try model.toJSON()
        return MutationEvent(modelName: modelType.schema.name,
                             data: data,
                             type: type,
                             source: source)
    }

}
