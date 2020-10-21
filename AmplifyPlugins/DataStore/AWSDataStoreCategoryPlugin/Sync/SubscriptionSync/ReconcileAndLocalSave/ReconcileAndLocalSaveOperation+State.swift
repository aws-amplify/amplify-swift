//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

@available(iOS 13.0, *)
extension ReconcileAndLocalSaveOperation {

    /// States are descriptive, they say what is happening in the system right now
    enum State {
        /// Waiting to be started by the queue
        case waiting

        /// Querying the local database for model data and sync metadata
        case querying(RemoteModel)

        /// Reconciling incoming remote model with local model and sync metadata
        case reconciling(RemoteModel, LocalMetadata?)

        /// Executing the reconciled disposition
        case executing(RemoteSyncReconciler.Disposition)

        case notifyingDropped(String)

        /// Notifying listeners and callbacks of completion
        case notifying(AppliedModel, Bool)

        /// Operation has successfully completed
        case finished

        /// Operation completed with an unexpected error
        case inError(AmplifyError)
    }
}
