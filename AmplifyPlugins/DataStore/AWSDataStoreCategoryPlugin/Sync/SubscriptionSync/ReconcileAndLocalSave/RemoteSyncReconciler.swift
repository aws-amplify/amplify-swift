//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Reconciles incoming sync mutations with the state of the local store, and mutation queue.
@available(iOS 13.0, *)
struct RemoteSyncReconciler {
    typealias LocalMetadata = ReconcileAndLocalSaveOperation.LocalMetadata
    typealias RemoteModel = ReconcileAndLocalSaveOperation.RemoteModel
    typealias SavedModel = ReconcileAndLocalSaveOperation.AppliedModel

    enum Disposition {
        case applyRemoteModel(RemoteModel, MutationEvent.MutationType)
        case dropRemoteModel(String)
    }

    static func reconcile(remoteModel: RemoteModel,
                          to localMetadata: LocalMetadata?,
                          pendingMutations: [MutationEvent]) -> Disposition {

        guard pendingMutations.isEmpty else {
            return .dropRemoteModel(remoteModel.model.modelName)
        }

        guard let localMetadata = localMetadata else {
            if remoteModel.syncMetadata.deleted {
                return .dropRemoteModel(remoteModel.model.modelName)
            } else {
                return .applyRemoteModel(remoteModel, .create)
            }
        }

        // Technically, we should never receive a subscription for a version we already have, but we'll be defensive
        // and make this check include the current version
        if remoteModel.syncMetadata.version >= localMetadata.version {
            if remoteModel.syncMetadata.deleted {
                return .applyRemoteModel(remoteModel, .delete)
            } else {
                return .applyRemoteModel(remoteModel, .update)
            }
        }

        return .dropRemoteModel(remoteModel.model.modelName)
    }
}
