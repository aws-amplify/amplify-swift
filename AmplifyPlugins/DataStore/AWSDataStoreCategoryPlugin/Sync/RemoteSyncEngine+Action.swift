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

    /// Actions are declarative, they say what I just did
    enum Action {
        // Startup/config actions
        case receivedStart

        case pausedSubscriptions
        case pausedMutationQueue(APICategoryGraphQLBehavior, StorageEngineAdapter)
        case initializedSubscriptions
        case performedInitialSync
        case activatedCloudSubscriptions(APICategoryGraphQLBehavior, MutationEventPublisher)
        case activatedMutationQueue
        case notifiedSyncStarted
        case cleanedUp(AmplifyError?)
        case scheduleRestart(AmplifyError?)

        // Terminal actions
        case receivedCancel
        case errored(AmplifyError?)

        var displayName: String {
            switch self {
            case .receivedStart:
                return "receivedStart"
            case .pausedSubscriptions:
                return "pausedSubscriptions"
            case .pausedMutationQueue:
                return "pausedMutationQueue"
            case .initializedSubscriptions:
                return "initializedSubscriptions"
            case .performedInitialSync:
                return "performedInitialSync"
            case .activatedCloudSubscriptions:
                return "activatedCloudSubscriptions"
            case .activatedMutationQueue:
                return "activatedMutationQueue"
            case .notifiedSyncStarted:
                return "notifiedSyncStarted"
            case .cleanedUp:
                return "cleanedUp"
            case .scheduleRestart:
                return "scheduleRestart"
            case .receivedCancel:
                return "receivedCancel"
            case .errored:
                return "errored"
            }

        }
    }
}
