//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint
import UserNotifications
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension AWSPinpointPushNotificationsPlugin {
    public func identifyUser(userId: String) async throws {
        let currentEndpointProfile = await pinpoint.currentEndpointProfile()
        currentEndpointProfile.addUserId(userId)
        try await pinpoint.updateEndpoint(with: currentEndpointProfile)
    }

    public func registerDevice(apnsToken: Data) async throws {
        let currentEndpointProfile = await pinpoint.currentEndpointProfile()
        currentEndpointProfile.setAPNsToken(apnsToken)
        do {
            try await pinpoint.updateEndpoint(with: currentEndpointProfile)
        } catch {
            throw error.pushNotificationsError
        }
    }

    public func recordNotificationReceived(_ userInfo: Notifications.Push.UserInfo) async throws {
        let applicationState = await self.applicationState
        await recordNotification(
            userInfo,
            applicationState: applicationState,
            action: .received(state: applicationState)
        )
    }

    public func recordNotificationOpened(_ response: UNNotificationResponse) async throws {
        let applicationState = await self.applicationState
        await recordNotification(
            response.notification.request.content.userInfo,
            applicationState: applicationState,
            action: .opened
        )
    }

    private func recordNotification(_ userInfo: [String: Any],
                                    applicationState: ApplicationState,
                                    action: PushNotification.Action) async {
        let userInfo: PushNotification.UserInfo = Dictionary(uniqueKeysWithValues: userInfo.map({($0, $1)}))
        await recordNotification(
            userInfo,
            applicationState: applicationState,
            action: action
        )
    }

    private func recordNotification(_ userInfo: PushNotification.UserInfo,
                                    applicationState: ApplicationState,
                                    action: PushNotification.Action) async {
        // Retrieve the payload from the notification
        guard let payload = userInfo.payload else {
            log.error("No valid Pinpoint Push payload found")
            return
        }

        // Create the push notifications event
        let eventType = "_\(payload.source.rawValue).\(action.eventType)"
        let pushNotificationEvent = pinpoint.createEvent(withEventType: eventType)

        // Add application state
        let applicationStateAttribute = applicationState.pinpointAttribute
        pushNotificationEvent.addAttribute(applicationStateAttribute.value,
                                           forKey: applicationStateAttribute.key)

        // Set global remote attributes
        await pinpoint.setRemoteGlobalAttributes(payload.attributes)

        // Record event
        do {
            try await pinpoint.record(pushNotificationEvent)
        } catch {
            log.error("Unable to record \(action.eventType) event")
        }

        switch action {
        case .opened:
            log.verbose("App launched from received notification.")
            if let deeplinkUrl = userInfo.deeplinkUrl {
                await handleDeeplinking(for: deeplinkUrl)
            }
        case .received(state: let state):
            log.verbose("Received notification with app on \(state.rawValue) state")
        }
    }

    @MainActor
    private func handleDeeplinking(for url: URL) {
        log.verbose("Received deeplink: \(url)")
    #if canImport(UIKit)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
    #endif
    }

    @MainActor
    private var applicationState: ApplicationState {
    #if canImport(UIKit)
        switch UIApplication.shared.applicationState {
        case .background:
            return .background
        case .active:
            return .foreground
        case .inactive:
            return .inactive
        @unknown default:
            log.warn("Application is in an unsupported state. Defaulting to inactive.")
            return .inactive
        }
    #elseif canImport(AppKit)
        let application = NSApplication.shared
        guard application.isRunning else {
            return .inactive
        }
        return application.isActive ? .foreground : .background
    #endif
    }
}
