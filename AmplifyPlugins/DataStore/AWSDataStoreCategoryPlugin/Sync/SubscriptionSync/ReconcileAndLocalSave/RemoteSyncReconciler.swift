//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
        case applyRemoteModel(RemoteModel)
        case dropRemoteModel(String)
        case error(DataStoreError)
    }

    static func reconcile(remoteModel: RemoteModel,
                          to localMetadata: LocalMetadata?,
                          pendingMutations: [MutationEvent]) -> Disposition {

        guard pendingMutations.isEmpty else {
            return .dropRemoteModel(remoteModel.model.modelName)
        }

        guard let localMetadata = localMetadata else {
            return .applyRemoteModel(remoteModel)
        }

        // Technically, we should never receive a subscription for a version we already have, but we'll be defensive
        // and make this check include the current version
        if remoteModel.syncMetadata.version >= localMetadata.version {
            return .applyRemoteModel(remoteModel)
        }

        return .dropRemoteModel(remoteModel.model.modelName)
    }
}
