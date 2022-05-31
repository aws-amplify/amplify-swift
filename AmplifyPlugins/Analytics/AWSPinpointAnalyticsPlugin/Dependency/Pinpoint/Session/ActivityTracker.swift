//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

protocol ActivityTrackerDelegate: AnyObject {
    func appDidMoveToBackground()
    func appDidMoveToForeground()
    func appWillTerminate()
    func backgroundTrackingDidTimeout()
}

class ActivityTracker {
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTimer: Timer? = nil {
        willSet {
            backgroundTimer?.invalidate()
        }
    }
    private let timeout: TimeInterval
    weak var delegate: ActivityTrackerDelegate? = nil
    
    init(timeout: TimeInterval) {
        self.timeout = timeout
    }
    
    func beginActivityTracking() {
        // TODO: Implement
        fatalError("Not yet implemented")
    }

    private func beginBackgroundTracking() {
        if timeout > 0 {
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: Constants.backgroundTask) { [weak self] in
                self?.stopBackgroundTracking()
            }
        }
        
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.stopBackgroundTracking()
        }
    }
    
    private func stopBackgroundTracking() {
        delegate?.backgroundTrackingDidTimeout()
        backgroundTimer = nil
        guard backgroundTask != .invalid else {
            return
        }
        
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

extension ActivityTracker {
    struct Constants {
        static let backgroundTask = "com.amazonaws.AWSPinpointSessionBackgroundTask"
    }
}
