//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

extension OutgoingMutationQueue {

    /// States are descriptive, they say what is happening in the system right now
    enum State: Sendable {
        // Startup/config states
        case notInitialized
        case stopped
        case starting(APICategoryGraphQLBehavior, MutationEventPublisher, IncomingEventReconciliationQueue?)

        // Event loop
        case requestingEvent
        case waitingForEventToProcess

        // Wrap-up
        // Spelled out rather than `BasicClosure` so the completion can be `@Sendable`, which the
        // `Sendable` conformance on this enum requires. `BasicClosure` is public API used widely,
        // so it is deliberately left alone.
        case stopping(@Sendable () -> Void)

        // Terminal states
        case inError(AmplifyError)

        var displayName: String {
            switch self {
            case .notInitialized:
                return "notInitialized"
            case .stopped:
                return "stopped"
            case .requestingEvent:
                return "requestingEvent"
            case .starting:
                return "starting"
            case .waitingForEventToProcess:
                return "waitingForEventToProcess"
            case .inError:
                return "inError"
            case .stopping:
                return "stopping"
            }
        }
    }
}
