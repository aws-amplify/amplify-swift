//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

extension OutgoingMutationQueue {

    /// States are descriptive, they say what is happening in the system right now
    enum State {
        // Startup/config states
        case notInitialized
        case notStarted
        case starting(APICategoryGraphQLBehavior, MutationEventPublisher)
        case waitingForSubscription

        // Event processing loop
        case requestingEvent
        case waitingForEvent
        case enqueuingEvent(MutationEvent)

        // Terminal states
        case finished
        case inError(AmplifyError)

        var displayName: String {
            switch self {
            case .enqueuingEvent:
                return "enqueuingEvent"
            case .finished:
                return "finished"
            case .inError:
                return "inError"
            case .notInitialized:
                return "notInitialized"
            case .notStarted:
                return "notStarted"
            case .requestingEvent:
                return "requestingEvent"
            case .starting:
                return "starting"
            case .waitingForEvent:
                return "waitingForEvent"
            case .waitingForSubscription:
                return "waitingForSubscription"
            }
        }
    }
}
