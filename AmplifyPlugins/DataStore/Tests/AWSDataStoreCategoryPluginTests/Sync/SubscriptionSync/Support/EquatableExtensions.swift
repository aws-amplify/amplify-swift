//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
@testable import AWSDataStorePlugin

extension RemoteSyncReconciler.Disposition: Equatable {
    public static func == (lhs: RemoteSyncReconciler.Disposition,
                           rhs: RemoteSyncReconciler.Disposition) -> Bool {
        switch (lhs, rhs) {
        case (.create(let model1), .create(let model2)):
            return model1.model.id == model2.model.id &&
                model1.model.modelName == model2.model.modelName
        case (.update(let model1), .update(let model2)):
            return model1.model.id == model2.model.id &&
                model1.model.modelName == model2.model.modelName
        case (.delete(let model1), .delete(let model2)):
            return model1.model.id == model2.model.id &&
                model1.model.modelName == model2.model.modelName
        default:
            return false
        }
    }
}

extension ReconcileAndLocalSaveOperation.Action: Equatable {
    public static func == (lhs: ReconcileAndLocalSaveOperation.Action,
                           rhs: ReconcileAndLocalSaveOperation.Action) -> Bool {
        switch (lhs, rhs) {
        case (.started(let models1), .started(let models2)):
            return models1.count == models2.count
        case (.reconciled, .reconciled):
            return true
        case (.cancelled, .cancelled):
            return true
        case (.errored(let error1), .errored(let error2)):
            return error1.errorDescription == error2.errorDescription
        default:
            return false
        }
    }
}

extension ReconcileAndLocalSaveOperation.State: Equatable {
    public static func == (lhs: ReconcileAndLocalSaveOperation.State,
                           rhs: ReconcileAndLocalSaveOperation.State) -> Bool {
        switch (lhs, rhs) {
        case (.waiting, .waiting):
            return true
        case (.reconciling(let models1), .reconciling(let models2)):
            return models1.count == models2.count
        case (.finished, .finished):
            return true
        case (.inError(let error1), .inError(let error2)):
            return error1.errorDescription == error2.errorDescription
        default:
            return false
        }
    }
}

extension ModelSyncedEvent: Equatable {
    public static func == (lhs: ModelSyncedEvent, rhs: ModelSyncedEvent) -> Bool {
        return lhs.modelName == rhs.modelName
            && lhs.isFullSync == rhs.isFullSync
            && lhs.isDeltaSync == rhs.isDeltaSync
            && lhs.added == rhs.added
            && lhs.updated == rhs.updated
            && lhs.deleted == rhs.deleted
    }
}

extension MutationSyncMetadata: Equatable {
    public static func == (lhs: MutationSyncMetadata, rhs: MutationSyncMetadata) -> Bool {
        return lhs.id == rhs.id
            && lhs.deleted == rhs.deleted
            && lhs.lastChangedAt == rhs.lastChangedAt
            && lhs.version == rhs.version
    }
}

extension MutationEvent: Equatable {
    public static func == (lhs: MutationEvent, rhs: MutationEvent) -> Bool {
        return lhs.id == rhs.id
            && lhs.modelId == rhs.modelId
            && lhs.modelName == rhs.modelName
            && lhs.json == rhs.json
            && lhs.mutationType == rhs.mutationType
            && lhs.createdAt == rhs.createdAt
            && lhs.version == rhs.version
            && lhs.inProcess == rhs.inProcess
            && lhs.graphQLFilterJSON == rhs.graphQLFilterJSON
    }
}
