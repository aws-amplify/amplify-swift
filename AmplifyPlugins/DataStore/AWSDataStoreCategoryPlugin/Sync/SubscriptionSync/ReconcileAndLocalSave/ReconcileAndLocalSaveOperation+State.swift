//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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

        /// Querying the pending mutations database
        case queryingPendingMutations([RemoteModel])

        /// Reconciling remote models against pending mutations
        case reconcilingWithPendingMutations([RemoteModel], [MutationEvent])

        /// Querying the local metadata database
        case queryingLocalMetadata([RemoteModel])

        /// Reconcile against local metadata
        case reconcilingWithLocalMetadata([RemoteModel], [LocalMetadata])

        /// Applying the remote model
        case applyingRemoteModels(RemoteSyncReconciler.Disposition)

        /// Notifying that the model was dropped
        case notifyingDropped(String)

        /// Notifying listeners and callbacks of completion
        case notifying(AppliedModel, MutationEvent.MutationType)

        /// Operation has successfully completed
        case finished

        /// Operation completed with an unexpected error
        case inError(AmplifyError)
    }
}
