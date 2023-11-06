//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation
@_spi(InternalAWSPinpoint) import InternalAWSPinpoint
import UserNotifications
#if canImport(WatchKit)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension AWSPinpointPushNotificationsPlugin {
    public func identifyUser(userId: String, userProfile: UserProfile?) async throws {
        let currentEndpointProfile = await pinpoint.currentEndpointProfile()
        currentEndpointProfile.addUserId(userId)
        if let userProfile = userProfile {
            currentEndpointProfile.addUserProfile(userProfile)
        }
        try await pinpoint.updateEndpoint(with: currentEndpointProfile,
                                          source: .pushNotifications)
    }

    public func registerDevice(apnsToken: Data) async throws {
        let currentEndpointProfile = await pinpoint.currentEndpointProfile()
        currentEndpointProfile.setAPNsToken(apnsToken)
        do {
            try await pinpoint.updateEndpoint(with: currentEndpointProfile,
                                              source: .pushNotifications)
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

#if !os(tvOS)
    public func recordNotificationOpened(_ response: UNNotificationResponse) async throws {
        let applicationState = await self.applicationState
        await recordNotification(
            response.notification.request.content.userInfo,
            applicationState: applicationState,
            action: .opened
        )
    }
#endif

    /// Retrieves the escape hatch to perform actions directly on PinpointClient.
    ///
    /// - Returns: PinpointClientProtocol instance
    public func getEscapeHatch() -> PinpointClientProtocol {
        pinpoint.pinpointClient
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
            log.error(
                """
                No valid Pinpoint Push payload found. The recordNotification API only supports Pinpoint Campaigns and Journeys. Test messages will not be recorded.
                """
            )
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
    #if canImport(UIKit) && !os(watchOS)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
    #endif
    }

    @MainActor
    private var applicationState: ApplicationState {
    #if canImport(WatchKit)
        let application = WKExtension.shared()
    #elseif canImport(UIKit)
        let application = UIApplication.shared
    #endif
        
    #if canImport(UIKit) || canImport(WatchKit)
        switch application.applicationState {
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
