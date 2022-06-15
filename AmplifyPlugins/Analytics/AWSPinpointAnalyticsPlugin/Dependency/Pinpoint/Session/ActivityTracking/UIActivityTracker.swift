//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(UIKit)
import Combine
import Foundation
import UIKit

class UIActivityTracker: ActivityTrackerBehaviour {
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTimer: Timer? = nil {
        willSet {
            backgroundTimer?.invalidate()
        }
    }
    private let backgroundTrackingTimeout: TimeInterval
    private let stateMachine: StateMachine<ApplicationState, ActivityEvent>
    private var stateMachineSink: AnyCancellable?
    
    init(backgroundTrackingTimeout: TimeInterval,
         stateMachine: StateMachine<ApplicationState, ActivityEvent>? = nil) {
        self.backgroundTrackingTimeout = backgroundTrackingTimeout
        self.stateMachine = stateMachine ?? StateMachine(initialState: .initializing,
                                                         resolver: ApplicationState.Resolver.resolve(currentState:event:))
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleApplicationStateChange),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleApplicationStateChange),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleApplicationStateChange),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willEnterForegroundNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willTerminateNotification,
                                                  object: nil)
    }
    
    func beginActivityTracking(_ listener: @escaping (ApplicationState) -> Void) {
        stateMachineSink = stateMachine
            .$state
            .sink { newState in
                listener(newState)
            }
    }

    private func beginBackgroundTracking() {
        if backgroundTrackingTimeout > 0 {
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: Constants.backgroundTask) { [weak self] in
                self?.stateMachine.process(.backgroundTrackingDidTimeout)
                self?.stopBackgroundTracking()
            }
        }
        
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: backgroundTrackingTimeout, repeats: false) { [weak self] _ in
            self?.stateMachine.process(.backgroundTrackingDidTimeout)
            self?.stopBackgroundTracking()
        }
    }
    
    private func stopBackgroundTracking() {
        backgroundTimer = nil
        guard backgroundTask != .invalid else {
            return
        }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    @objc private func handleApplicationStateChange(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            beginBackgroundTracking()
            stateMachine.process(.applicationDidMoveToBackground)
        case UIApplication.willEnterForegroundNotification:
            stopBackgroundTracking()
            stateMachine.process(.applicationWillMoveToForeground)
        case UIApplication.willTerminateNotification:
            stateMachine.process(.applicationWillTerminate)
        default:
            return
        }
    }
}

extension UIActivityTracker {
    struct Constants {
        static let backgroundTask = "com.amazonaws.AWSPinpointSessionBackgroundTask"
    }
}
#endif
