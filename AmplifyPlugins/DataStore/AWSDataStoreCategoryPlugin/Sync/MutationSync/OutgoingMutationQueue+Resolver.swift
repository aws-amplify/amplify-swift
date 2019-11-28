//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

extension OutgoingMutationQueue {

    struct Resolver {
        static func resolve(currentState: State, action: Action) -> State {
            switch (currentState, action) {

                // MARK: - Allowed transitions

            case (.notInitialized, .initialized):
                return .notStarted

            case (.notStarted, .receivedStart(let api, let mutationEventPublisher)):
                return .starting(api, mutationEventPublisher)

            case (.starting, .started):
                return .waitingForSubscription

            case (.waitingForSubscription, .receivedSubscription):
                return .requestingEvent

                // MARK: - Event processing loop

            case (.requestingEvent, .requestedEvent):
                return .waitingForEvent

            case (.requestingEvent, .receivedEvent(let mutationEvent)),
                 (.waitingForEvent, .receivedEvent(let mutationEvent)):
                // The subscription may deliver an event before we transition back to .waiting state, so we'll allow a
                // transition to .enqueuingEvent from either .requestingEvent or .waiting
                return .enqueuingEvent(mutationEvent)

            case (.enqueuingEvent, .enqueuedEvent):
                return .waitingForEvent

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
