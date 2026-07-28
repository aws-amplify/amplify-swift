//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if canImport(WatchKit)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Observes app lifecycle notifications and reports background/foreground transitions.
///
/// Isolated to the main actor because the platform frameworks post these
/// notifications on the main thread, which also makes the type implicitly
/// `Sendable` and removes the need to synchronize `isObserving` by hand.
@MainActor
final class ActivityTracker {
    private let onPause: @Sendable () -> Void
    private let onResume: @Sendable () -> Void
    private var isObserving = false

    private static let backgroundNotification: Notification.Name = {
        #if canImport(WatchKit)
        WKExtension.applicationDidEnterBackgroundNotification
        #elseif canImport(UIKit)
        UIApplication.didEnterBackgroundNotification
        #elseif canImport(AppKit)
        NSApplication.didHideNotification
        #endif
    }()

    private static let foregroundNotification: Notification.Name = {
        #if canImport(WatchKit)
        WKExtension.applicationWillEnterForegroundNotification
        #elseif canImport(UIKit)
        UIApplication.willEnterForegroundNotification
        #elseif canImport(AppKit)
        NSApplication.willUnhideNotification
        #endif
    }()

    init(
        onPause: @escaping @Sendable () -> Void,
        onResume: @escaping @Sendable () -> Void
    ) {
        self.onPause = onPause
        self.onResume = onResume
        self.isObserving = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackground),
            name: Self.backgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForeground),
            name: Self.foregroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Stops observing lifecycle notifications.
    ///
    /// Callbacks are guaranteed not to fire after this returns, so an owner being
    /// torn down cannot be resurrected by a notification that arrives later.
    /// Calling this more than once is a no-op.
    func stopTracking() {
        guard isObserving else { return }
        isObserving = false
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleBackground() {
        guard isObserving else { return }
        onPause()
    }

    @objc private func handleForeground() {
        guard isObserving else { return }
        onResume()
    }
}
