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

final class ActivityTracker: @unchecked Sendable {
    private let onPause: @Sendable () -> Void
    private let onResume: @Sendable () -> Void

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

    @objc private func handleBackground() {
        onPause()
    }

    @objc private func handleForeground() {
        onResume()
    }
}
