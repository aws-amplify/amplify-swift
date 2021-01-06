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

    /// Actions are declarative, they say what I just did
    enum Action {
        // Startup/config actions
        case initialized
        case receivedStart(APICategoryGraphQLBehavior, MutationEventPublisher)
        case receivedSubscription

        // Event loop
        case enqueuedEvent
        case processedEvent
        case resumedSyncingToCloud

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
            case .processedEvent:
                return "processedEvent"
            case .resumedSyncingToCloud:
                return "resumedSyncingToCloud"
            case .receivedCancel:
                return "receivedCancel"
            case .receivedStart:
                return "receivedStart"
            case .receivedSubscription:
                return "receivedSubscription"
            }
        }
    }

}
