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
    struct Resolver {
        static func resolve(currentState: State, action: Action) -> State {
            switch (currentState, action) {
            case (.notStarted, .receivedStart):
                return .pauseSubscriptions

            case (.pauseSubscriptions, .pausedSubscriptions):
                return .pauseMutationQueue

            case (.pauseMutationQueue, .pausedMutationQueue(let api, let storageEngineAdapter)):
                return .initializeSubscriptions(api, storageEngineAdapter)

            case (.initializeSubscriptions, .initializedSubscriptions):
                return .performInitialSync

            case (.performInitialSync, .performedInitialSync):
                return .activateCloudSubscriptions
            case (.performInitialSync, .errored(let error)):
                return .cleanup(error)

            case (.activateCloudSubscriptions, .activatedCloudSubscriptions(let api, let mutationEventPublisher)):
                return .activateMutationQueue(api, mutationEventPublisher)
            case (.activateCloudSubscriptions, .errored(let error)):
                return .cleanup(error)

            case (.activateMutationQueue, .activatedMutationQueue):
                return .notifySyncStarted

            case (.activateMutationQueue, .errored(let error)):
                return .cleanup(error)

            case (.notifySyncStarted, .notifiedSyncStarted):
                return .syncEngineActive

            case (.syncEngineActive, .errored(let error)):
                return .cleanup(error)

            case (.cleanup, .cleanedUp(let error)):
                return .scheduleRestart(error)

            case (.scheduleRestart, .scheduleRestartFinished):
                return .pauseSubscriptions

            default:
                log.warn("Unexpected state transition. In \(currentState.displayName), got \(action.displayName)")
                log.verbose("Unexpected state transition. In \(currentState), got \(action)")
                return currentState
            }
        }
    }
}
