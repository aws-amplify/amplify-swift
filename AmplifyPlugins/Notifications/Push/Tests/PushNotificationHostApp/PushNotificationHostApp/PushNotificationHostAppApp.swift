//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
		

import SwiftUI
import Amplify

@main
struct PushNotificationHostAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

@MainActor
class AppDelegate: NSObject { }

extension AppDelegate: UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            do {
                print("Did register remote notification with token", deviceToken)
                try await Amplify.Notifications.Push.registerDevice(apnsToken: deviceToken)
            } catch {
                print(#function, "Failed to registerDevice", error)
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print(#function, "Failed to register for remote notification", error)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any]
    ) async -> UIBackgroundFetchResult {
        do {
            try await Amplify.Notifications.Push.recordNotificationReceived(userInfo)
            Amplify.Analytics.flushEvents()
            print(#function, "Did recordNotificationReceived")
        } catch {
            print(#function, "Failed to recordNotificationReceived event", error)
        }
        return .noData
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
#if os(iOS)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        do {
            try await Amplify.Notifications.Push.recordNotificationOpened(response)
            Amplify.Analytics.flushEvents()
            print(#function, "Did recordNotificationOpened")
        } catch {
            print(#function, "Failed to recordNotificationOpened event", error)
        }
    }
#endif
}
