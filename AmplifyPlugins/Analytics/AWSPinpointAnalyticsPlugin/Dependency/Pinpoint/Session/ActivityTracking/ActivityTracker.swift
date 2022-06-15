//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

enum ActivityEvent {
    case applicationDidMoveToBackground
    case applicationWillMoveToForeground
    case applicationWillTerminate
    case backgroundTrackingDidTimeout
}

enum ApplicationState {
    case initializing
    case runningInForeground
    case runningInBackground(isStale: Bool)
    case terminated
    
    struct Resolver {
        static func resolve(currentState: ApplicationState, event: ActivityEvent) -> ApplicationState {
            if case .terminated = currentState {
                log.warn("Unexpected state transition. Received event \(event) in \(currentState) state.")
                return currentState
            }
            
            switch event {
            case .applicationWillTerminate:
                return .terminated
            case .applicationDidMoveToBackground:
                return .runningInBackground(isStale: false)
            case .applicationWillMoveToForeground:
                return .runningInForeground
            case .backgroundTrackingDidTimeout:
                return .runningInBackground(isStale: true)
            }
        }
    }
}

extension ApplicationState: Equatable {}

extension ApplicationState: DefaultLogger {}

protocol ActivityTrackerBehaviour {
    func beginActivityTracking(_ listener: @escaping (ApplicationState) -> Void)
}

class ActivityTracker {
    static func create(from context: PinpointContext) -> ActivityTrackerBehaviour {
#if !os(OSX)
        return UIActivityTracker(backgroundTrackingTimeout: context.configuration.sessionTimeout)
#else
        return EmptyTracker()
#endif
    }
    
    private class EmptyTracker: ActivityTrackerBehaviour {
        func beginActivityTracking(_ listener: @escaping (ApplicationState) -> Void) {}
    }
}
