//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

@available(iOS 13.0, *)
extension OutgoingMutationQueue {

    struct Resolver {
        // swiftlint:disable cyclomatic_complexity
        static func resolve(currentState: State, action: Action) -> State {
            switch (currentState, action) {

                // MARK: - Allowed transitions

            case (.notInitialized, .initialized):
                return .notStarted

            case (.notStarted, .receivedStart(let api, let mutationEventPublisher)):
                return .starting(api, mutationEventPublisher)
            case (_, .receivedStart):
                return .resumingMutationQueue

            case (.resumingMutationQueue, .resumedSyncingToCloud):
                return .resumed
            case (.resumed, .processedEvent):
                return .requestingEvent

            case (.starting, .receivedSubscription):
                return .requestingEvent

            case (.requestingEvent, .enqueuedEvent):
                return .waitingForEventToProcess

            case (.waitingForEventToProcess, .processedEvent):
                return .requestingEvent

                // MARK: - Actions that always transition state

            case (_, .errored(let amplifyError)):
                return .inError(amplifyError)

            case (_, .receivedCancel):
                return .finished

                // MARK: - Terminal states

            case (.finished, _):
                return currentState

            case (.inError, _):
                return currentState

            default:
                log.warn("Unexpected state transition. In \(currentState.displayName), got \(action.displayName)")
                log.verbose("Unexpected state transition. In \(currentState), got \(action)")
                return currentState
            }

        }
    }
}
