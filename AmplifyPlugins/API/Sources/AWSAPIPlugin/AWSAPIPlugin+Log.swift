//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AppSyncRealTimeClient

extension AWSAPIPlugin {
    var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName)
    }
}
