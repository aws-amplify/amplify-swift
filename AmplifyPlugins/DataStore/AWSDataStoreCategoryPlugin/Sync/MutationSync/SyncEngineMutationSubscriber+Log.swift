//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension SyncEngineMutationSubscriber {
    var log: Logger {
        Amplify.DataStore.log
    }
}
