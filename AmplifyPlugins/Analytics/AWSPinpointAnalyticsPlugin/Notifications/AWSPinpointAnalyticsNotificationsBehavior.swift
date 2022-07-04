//
//  File.swift
//  
//
//  Created by Costantino, Diego on 2022-05-31.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

public protocol AWSPinpointAnalyticsNotificationsBehavior {
    typealias UserInfo = [String: Any]
    
    func interceptDidFinishLaunchingWithOptions(launchOptions: LaunchOptions) async -> Bool
    
    
    /// Invoke this method from the `- application:didRegisterForRemoteNotificationsWithDeviceToken:` application delegate
    /// method.
    /// The Pinpoint targeting client must intercept this callback in order to report campaign analytics correctly.
    /// - Parameter deviceToken: A token that identifies the device to APNs.
    func interceptDidRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data) async
    
    
    /// For iOS 9 and below, intercept the `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` application
    /// delegate.
    ///
    /// For iOS 10 and above, invoke this method from the `userNotificationCenter(_:willPresent:withCompletionHandler:)` and
    /// `userNotificationCenter(_:didReceive:withCompletionHandler:)` UserNotificationCenter methods. When invoking this method
    /// from `willPresent`, pass in `notification.request.content.userInfo` as userInfo. When invoking this method on
    /// `didReceive`, pass in `response.notification.request.content.userInfo` as `userInfo`.
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

public enum AWSPinpointPushEvent {
    case opened
    case received
}

extension AWSPinpointAnalyticsClientBehavior {
    public var areNotificationsEnabled: Bool {
#if canImport(UIKit)
        return UIApplication.shared.isRegisteredForRemoteNotifications
#else
        // TODO: Update this if needed to support multiplatform
        return false
#endif
    }
}
