//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

@available(iOS 13.0, *)
extension ReconcileAndLocalSaveOperation {

    /// States are descriptive, they say what is happening in the system right now
    enum State {
        case waiting
        case deserializing(AnyModel)
        case querying(CloudModel)
        case reconciling(CloudModel, LocalModel?)
        case saving(CloudModel)
        case notifying(SavedModel)

        // Terminal states
        case finished
        case inError(AmplifyError)
    }
}
