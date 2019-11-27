//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

extension OutgoingMutationQueue {

    /// Actions are declarative, they say what I just did
    enum Action {
        // Startup/config actions
        case initialized
        case receivedStart(APICategoryGraphQLBehavior, MutationEventPublisher)
        case started
        case receivedSubscription

        // Event processing loop
        case requestedEvent
        case receivedEvent(MutationEvent)
        case enqueuedEvent(MutationEvent)

        // Terminal actions
        case receivedCancel
        case errored(AmplifyError)

        var displayName: String {
            switch self {
            case .enqueuedEvent:
                return "enqueuedEvent"
            case .errored:
                return "errored"
            case .initialized:
                return "initialized"
            case .receivedCancel:
                return "receivedCancel"
            case .receivedEvent:
                return "receivedEvent"
            case .receivedStart:
                return "receivedStart"
            case .receivedSubscription:
                return "receivedSubscription"
            case .requestedEvent:
                return "requestedEvent"
            case .started:
                return "started"
            }
        }
    }

}
