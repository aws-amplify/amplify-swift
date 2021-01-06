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

    /// States are descriptive, they say what is happening in the system right now
    enum State {
        // Startup/config states
        case notInitialized
        case notStarted
        case starting(APICategoryGraphQLBehavior, MutationEventPublisher)

        // Event loop
        case requestingEvent
        case waitingForEventToProcess
        case resumingMutationQueue
        case resumed

        // Terminal states
        case finished
        case inError(AmplifyError)

        var displayName: String {
            switch self {
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
            case .waitingForEventToProcess:
                return "waitingForEventToProcess"
            case .resumingMutationQueue:
                return "resumingMutationQueue"
            case .resumed:
                return "resumed"
            }
        }
    }
}
