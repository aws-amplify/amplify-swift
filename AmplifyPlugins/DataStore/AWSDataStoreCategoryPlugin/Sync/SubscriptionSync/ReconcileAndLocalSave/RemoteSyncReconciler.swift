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

    private weak var mutationEventSource: MutationEventSource?

    private let cloudModel: CloudModel
    private let localModel: LocalModel?
    private var localMutations: [MutationEvent]

    enum Disposition {
        case apply
    }

    init(mutationEventSource: MutationEventSource, cloudModel: CloudModel, to localModel: LocalModel?) {
        self.mutationEventSource = mutationEventSource
        self.cloudModel = cloudModel
        self.localModel = localModel

        self.localMutations = []
    }

    func reconcile() -> Disposition {
        return .apply
    }
}
