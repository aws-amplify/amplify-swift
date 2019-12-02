//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Reconciles incoming sync mutations with the state of the local store, and mutation queue.
@available(iOS 13.0, *)
struct RemoteSyncReconciler {
    typealias LocalModel = ReconcileAndLocalSaveOperation.LocalModel
    typealias CloudModel = ReconcileAndLocalSaveOperation.CloudModel
    typealias SavedModel = ReconcileAndLocalSaveOperation.SavedModel

    private weak var storageAdapter: StorageEngineAdapter?

    private let cloudModel: CloudModel
    private let localModel: LocalModel?
    private var localMutations: [MutationEvent]

    enum Disposition {
        case apply
        case error(DataStoreError)
    }

    init(cloudModel: CloudModel, to localModel: LocalModel?, storageAdapter: StorageEngineAdapter) {
        self.storageAdapter = storageAdapter
        self.cloudModel = cloudModel
        self.localModel = localModel

        self.localMutations = []
    }

    func reconcile() -> Disposition {
        guard let storageAdapter = storageAdapter else {
            return .error(DataStoreError.nilStorageAdapter())
        }

        let semaphore = DispatchSemaphore(value: 1)
        var pendingMutationResultFromQuery: DataStoreResult<[MutationEvent]>?
        MutationEvent.pendingMutationEvents(
            forModelId: cloudModel.model.id,
            storageAdapter: storageAdapter) {
                pendingMutationResultFromQuery = $0
                semaphore.signal()
        }
        semaphore.wait()

        guard let pendingMutationResult = pendingMutationResultFromQuery else {
            let dataStoreError = DataStoreError.unknown("Unable to query pending mutation events",
                                                        AmplifyErrorMessages.shouldNotHappenReportBugToAWS())
            return .error(dataStoreError)
        }

        let pendingMutations: [MutationEvent]
        switch pendingMutationResult {
        case .failure(let dataStoreError):
            return .error(dataStoreError)
        case .success(let mutationEvents):
            pendingMutations = mutationEvents
        }

        return reconcile(cloudModel: cloudModel, localModel: localModel, pendingMutations: pendingMutations)
    }

    func reconcile(cloudModel: CloudModel,
                   localModel: LocalModel?,
                   pendingMutations: [MutationEvent]) -> Disposition {

        if pendingMutations.isEmpty && localModel == nil {
            return .apply
        }

        return .apply

        //        if cloudModel.version > localModel.version {
        //            let reconciledAction = Action.reconciled(cloudModel)
        //            stateMachine.notify(action: reconciledAction)
        //        } else if cloudModel.version < localModel.version {
        //            let conflictAction = Actions.conflicted(cloudModel, localModel)
        //            stateMachine.notify(action: conflictAction)
        //        } else {
        //            let duplicateEventAction = ???
        //            stateMachine.notify(action: duplicateEventAction)
        //        }

    }

}
