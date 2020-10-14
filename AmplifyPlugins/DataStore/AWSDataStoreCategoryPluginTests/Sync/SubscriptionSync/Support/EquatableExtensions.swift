//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
@testable import AWSDataStoreCategoryPlugin

extension RemoteSyncReconciler.Disposition: Equatable {
    public static func == (lhs: RemoteSyncReconciler.Disposition,
                           rhs: RemoteSyncReconciler.Disposition) -> Bool {
        switch (lhs, rhs) {
        case (.applyRemoteModel(let rm1), .applyRemoteModel(let rm2)):
            return rm1.model.id == rm2.model.id &&
                rm1.model.modelName == rm2.model.modelName
        case (.dropRemoteModel, .dropRemoteModel):
            return true
        case (.error(let error1), .error(let error2)):
            return error1.errorDescription == error2.errorDescription
        default:
            return false
        }
    }
}

extension ReconcileAndLocalSaveOperation.Action: Equatable {
    public static func == (lhs: ReconcileAndLocalSaveOperation.Action,
                           rhs: ReconcileAndLocalSaveOperation.Action) -> Bool {
        switch (lhs, rhs) {
        case (.started(let model1), .started(let model2)):
            return model1.model.id == model2.model.id
                && model1.model.modelName == model2.model.modelName
        case (.queried(let model1, let lmetadata1), .queried(let model2, let lmetadata2)):
            return model1.model.id == model2.model.id
                && lmetadata1?.id == lmetadata2?.id
                && model1.model.modelName == model2.model.modelName
        case (.reconciled(let disposition1), .reconciled(let disposition2)):
            return disposition1 == disposition2
        case (.applied(let model1, let existsLocally1), .applied(let model2, let existsLocally2)):
            return model1.model.id == model2.model.id
                && model1.model.modelName == model2.model.modelName
                && existsLocally1 == existsLocally2
        case (.dropped, dropped):
            return true
        case (.notified, .notified):
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
        case (.querying(let model1), .querying(let model2)):
            return model1.model.id == model2.model.id
                && model1.model.modelName == model2.model.modelName
        case (.reconciling(let model1, let lmetadata1), .reconciling(let model2, let lmetadata2)):
            return model1.model.id == model2.model.id
                && lmetadata1?.id == lmetadata2?.id
                && model1.model.modelName == model2.model.modelName
        case (.executing(let disposition1), .executing(let disposition2)):
            return disposition1 == disposition2
        case (.notifying(let model1, let existsLocally1), .notifying(let model2, let existsLocally2)):
            return model1.model.id == model2.model.id
                && model1.model.modelName == model2.model.modelName
                && existsLocally1 == existsLocally2
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
