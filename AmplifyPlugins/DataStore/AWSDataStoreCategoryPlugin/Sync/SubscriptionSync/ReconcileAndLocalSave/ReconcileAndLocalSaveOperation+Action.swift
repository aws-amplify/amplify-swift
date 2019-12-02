//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

@available(iOS 13.0, *)
extension ReconcileAndLocalSaveOperation {

    /// Actions are declarative, they say what I just did
    enum Action {
        case started(CloudModel)
        case deserialized(CloudModel)
        case queried(CloudModel, LocalModel?)
        case reconciled(CloudModel)
        case cancelled
        case conflicted(CloudModel, LocalModel)
        case saved(SavedModel)
        case notified
        case errored(AmplifyError)
    }

}
