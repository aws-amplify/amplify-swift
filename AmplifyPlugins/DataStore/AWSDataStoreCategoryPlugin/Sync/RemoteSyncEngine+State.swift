//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
@available(iOS 13.0, *)
extension RemoteSyncEngine {

    /// States are descriptive, they say what is happening in the system right now
    enum State {
        case notStarted

        case pauseSubscriptions
        case pauseMutationQueue
        case initializeSubscriptions(APICategoryGraphQLBehavior, StorageEngineAdapter)
        case performInitialSync
        case activateCloudSubscriptions
        case activateMutationQueue(APICategoryGraphQLBehavior, MutationEventPublisher)
        case notifySyncStarted

        case syncEngineActive

        case cleanup(AmplifyError)
        var displayName: String {
            switch self {
            case .notStarted:
                return "notStarted"
            case .pauseSubscriptions:
                return "pauseCloudSubscriptions"
            case .pauseMutationQueue:
                return "pauseMutationQueue"
            case .initializeSubscriptions:
                return "initializeSubscriptions"
            case .performInitialSync:
                return "performInitialSync"
            case .activateCloudSubscriptions:
                return "activateCloudSubscriptions"
            case .activateMutationQueue:
                return "activateMutationQueue"
            case .notifySyncStarted:
                return "notifySyncStarted"
            case .syncEngineActive:
                return "syncEngineActive"
            case .cleanup:
                return "cleanup"
            }
        }
    }
}
