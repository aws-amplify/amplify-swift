//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

public struct OutboxMutationEvent {
    public var modelName: String
    public var element: OutboxMutationEventMetadata

    public static func fromModelWithMetadata(modelName: String,
                                             model: Model,
                                             mutationSync: MutationSync<AnyModel>) -> OutboxMutationEvent {
        let element = OutboxMutationEventMetadata(model: model,
                                                  version: mutationSync.syncMetadata.version,
                                                  lastChangedAt: mutationSync.syncMetadata.lastChangedAt,
                                                  deleted: mutationSync.syncMetadata.deleted)
        return fromModel(modelName: modelName, element: element)
    }

    public static func fromModelWithoutMetadata(modelName: String,
                                                model: Model) -> OutboxMutationEvent {
        let element = OutboxMutationEventMetadata(model: model)
        return fromModel(modelName: modelName, element: element)
    }

    public static func fromModel(modelName: String, element: OutboxMutationEventMetadata) -> OutboxMutationEvent {
        return OutboxMutationEvent(modelName: modelName, element: element)
    }
}

public struct OutboxMutationEventMetadata {
    public let model: Model
    public var version: Int?
    public var lastChangedAt: Int?
    public var deleted: Bool?
}
