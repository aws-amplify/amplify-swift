//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyUtilsNotifications
import Foundation
import UserNotifications

@_spi(InternalAWSPinpoint)
public protocol RemoteNotificationsBehaviour {
    var isRegisteredForRemoteNotifications: Bool { get async }
    func requestAuthorization(_ options: UNAuthorizationOptions) async throws -> Bool
    func registerForRemoteNotifications() async
}

@_spi(InternalAWSPinpoint)
extension RemoteNotificationsBehaviour where Self == AmplifyRemoteNotificationsHelper {
    public static var `default`: RemoteNotificationsBehaviour {
        AmplifyRemoteNotificationsHelper.shared
    }
}

@_spi(InternalAWSPinpoint)
public struct AmplifyRemoteNotificationsHelper: RemoteNotificationsBehaviour {
    private init() {}

    static var shared: RemoteNotificationsBehaviour = AmplifyRemoteNotificationsHelper()

    public var isRegisteredForRemoteNotifications: Bool {
        get async {
            await AUNotificationPermissions.allowed
        }
    }

    public func requestAuthorization(_ options: UNAuthorizationOptions) async throws -> Bool {
        do {
            return try await AUNotificationPermissions.request(options)
        } catch {
            throw PushNotificationsError.configuration(
                "An error ocurred while trying to request Notifications permissions",
                "Please try again.",
                error
            )
        }
    }

    public func registerForRemoteNotifications() async {
        await AUNotificationPermissions.registerForRemoteNotifications()
    }
}

