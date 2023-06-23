//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
		

import SwiftUI
import Amplify
import UserNotifications
#if os(watchOS)
typealias ApplicationDelegateAdaptor = WKApplicationDelegateAdaptor
typealias Application = WKApplication
typealias ApplicationDelegate = WKApplicationDelegate
typealias BackgroundFetchResult = WKBackgroundFetchResult
#else
typealias ApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
typealias Application = UIApplication
typealias ApplicationDelegate = UIApplicationDelegate
typealias BackgroundFetchResult = UIBackgroundFetchResult
#endif

@main
struct PushNotificationHostAppApp: App {
    @ApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

@MainActor
class AppDelegate: NSObject { }

extension AppDelegate: ApplicationDelegate {
#if os(watchOS)
    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        registerDevice(deviceToken)
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
        print(#function, "Failed to register for remote notification", error)
    }
#else
    func application(
        _ application: Application,
        didFinishLaunchingWithOptions launchOptions: [Application.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(
        _ application: Application,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        registerDevice(deviceToken)
    }
    
    func application(
        _ application: Application,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print(#function, "Failed to register for remote notification", error)
    }
#endif

    func application(
        _ application: Application,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any]
    ) async -> BackgroundFetchResult {
        await recordNotificationReceived(userInfo)
        return .noData
    }
    
    private func registerDevice(_ deviceToken: Data) {
        Task {
            do {
                print("Did register remote notification with token", deviceToken)
                try await Amplify.Notifications.Push.registerDevice(apnsToken: deviceToken)
            } catch {
                print(#function, "Failed to registerDevice", error)
            }
        }
    }
    
    private func recordNotificationReceived(_ userInfo: [AnyHashable : Any]) async {
        do {
            try await Amplify.Notifications.Push.recordNotificationReceived(userInfo)
            Amplify.Analytics.flushEvents()
            print(#function, "Did recordNotificationReceived")
        } catch {
            print(#function, "Failed to recordNotificationReceived event", error)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

#if os(watchOS)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        await recordNotificationReceived(notification.request.content.userInfo)
        return .sound
    }
#endif

#if !os(tvOS)
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
