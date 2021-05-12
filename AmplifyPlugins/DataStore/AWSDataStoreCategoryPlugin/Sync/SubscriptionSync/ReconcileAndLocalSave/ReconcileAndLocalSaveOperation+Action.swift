//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

@available(iOS 13.0, *)
extension ReconcileAndLocalSaveOperation {

    /// Actions are declarative, they say what I just did
    enum Action {
        /// Operation has been started by the queue
        case started(RemoteModel)

        /// Operation has retrieved pending mutations
        case queriedPendingMutations(RemoteModel)

        /// Operation has reconciled the local metadata to apply the remote model.
        case reconciledAsApply(RemoteModel, MutationEvent.MutationType)

        /// Operation has applied the incoming RemoteModel to the local database per the reconciled disposition. This
        /// could result in either a save to the local database, or a delete from the local database.
        case applied(AppliedModel, MutationEvent.MutationType)

        /// Operation dropped the remote model per the reconciled disposition.
        case dropped(modelName: String)

        /// Operation notified listeners and callbacks of completion
        case notified

        /// Operation has been cancelled by the queue
        case cancelled

        /// Operation has encountered an error
        case errored(AmplifyError)
    }

}
