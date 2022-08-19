//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

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

class ActivityTracker: ActivityTrackerBehaviour {

#if canImport(UIKit)
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
#endif

    private var backgroundTimer: Timer? {
        willSet {
            backgroundTimer?.invalidate()
        }
    }
    private let backgroundTrackingTimeout: TimeInterval
    private let stateMachine: StateMachine<ApplicationState, ActivityEvent>
    private var stateMachineSubscriberToken: StateMachineSubscriberToken?

    private static let applicationDidMoveToBackgroundNotification: Notification.Name = {
    #if canImport(UIKit)
        UIApplication.didEnterBackgroundNotification
    #else
        NSApplication.didResignActiveNotification
    #endif
    }()

    private static  let applicationWillMoveToForegoundNotification: Notification.Name = {
    #if canImport(UIKit)
        UIApplication.willEnterForegroundNotification
    #else
        NSApplication.willBecomeActiveNotification
    #endif
    }()

    private static  var applicationWillTerminateNotification: Notification.Name = {
    #if canImport(UIKit)
        UIApplication.willTerminateNotification
    #else
        NSApplication.willTerminateNotification
    #endif
    }()

    private let notifications = [
        applicationDidMoveToBackgroundNotification,
        applicationWillMoveToForegoundNotification,
        applicationWillTerminateNotification
    ]

    init(backgroundTrackingTimeout: TimeInterval,
         stateMachine: StateMachine<ApplicationState, ActivityEvent>? = nil) {
        self.backgroundTrackingTimeout = backgroundTrackingTimeout
        self.stateMachine = stateMachine ?? StateMachine(initialState: .initializing,
                                                         resolver: ApplicationState.Resolver.resolve(currentState:event:))
        for notification in notifications {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleApplicationStateChange),
                                                   name: notification,
                                                   object: nil)
        }
    }

    deinit {
        for notification in notifications {
            NotificationCenter.default.removeObserver(self,
                                                      name: notification,
                                                      object: nil)
        }
        stateMachineSubscriberToken = nil
    }

    func beginActivityTracking(_ listener: @escaping (ApplicationState) -> Void) {
        stateMachineSubscriberToken = stateMachine.subscribe(listener)
    }

    private func beginBackgroundTracking() {
    #if canImport(UIKit)
        if backgroundTrackingTimeout > 0 {
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: Constants.backgroundTask) { [weak self] in
                self?.stateMachine.process(.backgroundTrackingDidTimeout)
                self?.stopBackgroundTracking()
            }
        }
    #endif
        guard backgroundTrackingTimeout != .infinity else { return }
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: backgroundTrackingTimeout, repeats: false) { [weak self] _ in
            self?.stateMachine.process(.backgroundTrackingDidTimeout)
            self?.stopBackgroundTracking()
        }
    }

    private func stopBackgroundTracking() {
        backgroundTimer = nil
    #if canImport(UIKit)
        guard backgroundTask != .invalid else {
            return
        }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    #endif
    }

    @objc private func handleApplicationStateChange(_ notification: Notification) {
        switch notification.name {
        case Self.applicationDidMoveToBackgroundNotification:
            beginBackgroundTracking()
            stateMachine.process(.applicationDidMoveToBackground)
        case Self.applicationWillMoveToForegoundNotification:
            stopBackgroundTracking()
            stateMachine.process(.applicationWillMoveToForeground)
        case Self.applicationWillTerminateNotification:
            stateMachine.process(.applicationWillTerminate)
        default:
            return
        }
    }
}

#if canImport(UIKit)
extension ActivityTracker {
    struct Constants {
        static let backgroundTask = "com.amazonaws.AWSPinpointSessionBackgroundTask"
    }
}
#endif
