//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import StoreKit
#if canImport(UIKit)
import UIKit
#endif

public protocol AWSPinpointAnalyticsNotificationsBehavior {
    typealias UserInfo = [String: Any]

    /// Invoke this method from the `- application:didFinishLaunchingWithOptions:` application delegate method.
    ///
    /// The Pinpoint targeting client must intercept this callback in order to report campaign analytics correctly.
    /// - Parameter launchOptions: A dictionary indicating the reason the app was launched (if any). The contents of this dictionary
    /// may be empty in situations where the user launched the app directly.
    /// - Returns:
    func interceptDidFinishLaunchingWithOptions(launchOptions: LaunchOptions) async -> Bool

    /// Invoke this method from the `- application:didRegisterForRemoteNotificationsWithDeviceToken:` application delegate
    /// method.
    ///
    /// The Pinpoint targeting client must intercept this callback in order to report campaign analytics correctly.
    /// - Parameter deviceToken: A token that identifies the device to APNs.
    func interceptDidRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data) async

    /// Invoke this method from the appropiate app delegate methods.
    ///
    /// - For iOS 9 and below, invoke this method from the `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` application
    /// delegate.
    ///
    /// - For iOS 10 and above, invoke this method from the following `UNUserNotificationCenterDelegate` methods:
    ///   - `userNotificationCenter(_:willPresent:withCompletionHandler:)`. Pass in `notification.request.content.userInfo` as `userInfo`.
    ///   - `userNotificationCenter(_:didReceive:withCompletionHandler:)`. Pass in `response.notification.request.content.userInfo` as `userInfo`.
    ///
    /// The Pinpoint targeting client must intercept this callback in order to report campaign analytics correctly. Optionally
    /// specify 'shouldHandleNotificationDeepLink' to control whether or not the notification manager should attempt to open
    /// the remote notification deeplink, if present.
    ///
    /// - Parameter userInfo: A dictionary that contains information related to the remote notification, potentially including a badge number for the app icon, an alert sound, an alert message to display to the user, a notification identifier, and custom data.
    /// The provider originates it as a JSON-defined dictionary that the system converts to an `Dictionary`.
    /// - Parameter pushEvent: Event for the push notification which is either `received` or `opened`. Defaults to `received`.
    /// - Parameter shouldHandleNotificationDeepLink: Whether or not notification manager should attempt to open the remote notification deeplink, if present.
    func interceptDidReceiveRemoteNotification(userInfo: UserInfo,
                                               pushEvent: AWSPinpointPushEvent,
                                               shouldHandleNotificationDeepLink: Bool) async
}

// MARK: - AWSPinpointNotifications + LaunchOptions
public extension AWSPinpointAnalyticsNotificationsBehavior {
#if canImport(UIKit)
    typealias LaunchOptions = [UIApplication.LaunchOptionsKey: Any]
#else
    typealias LaunchOptions = [String: Any]
#endif
}

// MARK: - AnalyticsNotificationsBehavior + Default values
public extension AWSPinpointAnalyticsNotificationsBehavior {
    /// Invoke this method from the appropiate app delegate methods.
    ///
    /// - For iOS 9 and below, invoke this method from the `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` application
    /// delegate.
    ///
    /// - For iOS 10 and above, invoke this method from the following `UNUserNotificationCenterDelegate` methods:
    ///   - `userNotificationCenter(_:willPresent:withCompletionHandler:)`. Pass in `notification.request.content.userInfo` as `userInfo`.
    ///   - `userNotificationCenter(_:didReceive:withCompletionHandler:)`. Pass in `response.notification.request.content.userInfo` as `userInfo`.
    ///
    /// The Pinpoint targeting client must intercept this callback in order to report campaign analytics correctly. Optionally
    /// specify 'shouldHandleNotificationDeepLink' to control whether or not the notification manager should attempt to open
    /// the remote notification deeplink, if present.
    ///
    /// - Parameter userInfo: A dictionary that contains information related to the remote notification, potentially including a badge number for the app icon, an alert sound, an alert message to display to the user, a notification identifier, and custom data.
    /// The provider originates it as a JSON-defined dictionary that the system converts to an `Dictionary`.
    /// - Parameter pushEvent: Event for the push notification which is either `received` or `opened`. Defaults to `received`.
    /// - Parameter shouldHandleNotificationDeepLink: Whether or not notification manager should attempt to open the remote notification deeplink, if present.
    func interceptDidReceiveRemoteNotification(userInfo: UserInfo,
                                               shouldHandleNotificationDeepLink: Bool) async {
        await interceptDidReceiveRemoteNotification(userInfo: userInfo,
                                                    pushEvent: .received,
                                                    shouldHandleNotificationDeepLink: shouldHandleNotificationDeepLink)
    }
}

public enum AWSPinpointPushEvent {
    case opened
    case received
}
