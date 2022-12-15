//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import UserNotifications

extension Notifications.Push {
#if canImport(UIKit)
    public typealias ApplicationDelegate = UIApplicationDelegate
    public typealias Application = UIApplication
#elseif canImport(AppKit)
    public typealias ApplicationDelegate = NSApplicationDelegate
    public typealias Application = NSApplication
#endif

    /// The default AppDelegate that calls the Push Notifications category methods in order to integrate with Amplify Push Notifications
    open class AppDelegate: NSObject {
        public override init() {
            super.init()
            UNUserNotificationCenter.current().delegate = self
        }
    }
}

// MARK: - ApplicationDelegate
extension Notifications.Push.AppDelegate: Notifications.Push.ApplicationDelegate {
    open func application(_ application: Notifications.Push.Application,
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            try? await Amplify.Notifications.Push.registerDevice(apnsToken: deviceToken)
        }
    }

    open func application(_ application: Notifications.Push.Application,
                          didFailToRegisterForRemoteNotificationsWithError error: Error) {
        let payload = HubPayload(
            eventName: HubPayload.EventName.Notifications.Push.registerForRemoteNotifications,
            data: error
        )
        Amplify.Hub.dispatch(to: .pushNotifications, payload: payload)
    }

#if canImport(UIKit)
    @discardableResult
    open func application(_ application: UIApplication,
                          didReceiveRemoteNotification userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {

        await Amplify.Notifications.Push.recordNotificationReceived(userInfo)
        return .noData
    }
#elseif canImport(AppKit)
    open func application(_ application: NSApplication,
                          didReceiveRemoteNotification userInfo: [String : Any]) {
        Task {
            await Amplify.Notifications.Push.recordNotificationReceived(userInfo)
        }
    }
#endif
}

// MARK: - UNUserNotificationCenterDelegate
extension Notifications.Push.AppDelegate: UNUserNotificationCenterDelegate {
    @MainActor
    open func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     didReceive response: UNNotificationResponse) async {
        await Amplify.Notifications.Push.recordNotificationOpened(response)
    }
}

// MARK: - ObservableObject
extension Notifications.Push.AppDelegate: ObservableObject {}
