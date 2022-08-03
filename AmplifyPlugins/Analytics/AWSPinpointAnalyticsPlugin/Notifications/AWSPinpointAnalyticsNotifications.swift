//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
#if canImport(UIKit)
import UIKit
#endif

class AWSPinpointAnalyticsNotifications: AWSPinpointAnalyticsNotificationsBehavior {
    private var previousEventSource: EventSource = .unknown
    private let analyticsClient: AnalyticsClientBehaviour
    private let endpointClient: EndpointClientBehaviour
    private let userDefaults: UserDefaultsBehaviour

    internal init(analyticsClient: AnalyticsClientBehaviour,
                  endpointClient: EndpointClientBehaviour,
                  userDefaults: UserDefaultsBehaviour) {
        self.analyticsClient = analyticsClient
        self.endpointClient = endpointClient
        self.userDefaults = userDefaults
    }

    // MARK: - Public APIs
    func interceptDidFinishLaunchingWithOptions(launchOptions: LaunchOptions) async -> Bool {
        guard let notificationPayload = remoteNotificationPayload(fromLaunchOptions: launchOptions),
              isValidPinpointNotification(payload: notificationPayload) else {
            return true
        }

        let (eventSource, pinpointMetadata) = pinpointMetadata(fromPayload: notificationPayload)

        await self.addGlobalEventSourceMetadata(eventMetadata: pinpointMetadata,
                                                eventSource: eventSource)
        await recordEventForNotification(metadata: pinpointMetadata,
                                         eventSource: eventSource,
                                         pushEvent: .opened,
                                         pushAction: .openedNotification)
        return true
    }

    func interceptDidRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data) async {
        let currentToken = self.userDefaults.data(forKey: EndpointClient.Constants.deviceTokenKey)
        guard currentToken != deviceToken else {
            return
        }

        self.userDefaults.save(deviceToken, forKey: EndpointClient.Constants.deviceTokenKey)
        do {
            try await self.endpointClient.updateEndpointProfile()
        } catch {
            log.error("Failed updating endpoint profile with error: \(error)")
        }
    }

    func interceptDidReceiveRemoteNotification(userInfo: UserInfo,
                                               pushEvent: AWSPinpointPushEvent = .received,
                                               shouldHandleNotificationDeepLink: Bool) async {
        let (eventSource, metadata) = pinpointMetadata(fromPayload: userInfo)
        let pushAction = makePinpointPushAction(fromEvent: pushEvent)

        switch pushAction {
        case .openedNotification:
            log.verbose("App launched from received notification.")
            await self.addGlobalEventSourceMetadata(eventMetadata: metadata, eventSource: eventSource)
            await self.recordEventForNotification(metadata: metadata,
                                                  eventSource: eventSource,
                                                  pushEvent: .opened,
                                                  pushAction: pushAction)

            if shouldHandleNotificationDeepLink {
                self.handleDeepLinkForNotification(userInfo: userInfo)
            }

        case .receivedBackground:
            log.verbose("Received notification with app in background.")
            await self.addGlobalEventSourceMetadata(eventMetadata: metadata, eventSource: eventSource)
            await self.recordEventForNotification(metadata: metadata,
                                                  eventSource: eventSource,
                                                  pushEvent: .received,
                                                  pushAction: pushAction)

        case .receivedForeground:
            log.verbose("Received notification with app in foreground.")
            // Not adding global event source metadata because if the app session is already running,
            // the session should not contribute to the new push notification that is being received
            await self.recordEventForNotification(metadata: metadata,
                                                  eventSource: eventSource,
                                                  pushEvent: .received,
                                                  pushAction: pushAction)

        case .unknown:
            log.verbose("Received notification with app in unknown state.")
        }
    }

    // MARK: Helpers
    /// Given a notification payload, returns a Pinpoint payload if available
    /// - Parameter notification: remote notification payload
    /// - Returns: Pinpoint payload or nil
    private func pinpointPayloadFromNotificationPayload(notification: UserInfo) -> [String: Any]? {
        guard let dataPayload = notification[PinpointContext.Constants.Notifications.dataKey] as? [String: Any],
              let pinpointMetadata = dataPayload[PinpointContext.Constants.Notifications.pinpointKey] as? [String: Any] else {
            return nil
        }
        return pinpointMetadata
    }

    private func recordEventForNotification(metadata: UserInfo?,
                                            eventSource: EventSource,
                                            pushEvent: AWSPinpointPushEvent,
                                            pushAction: AWSPinpointPushAction,
                                            withIdentifier identifier: String? = nil) async {
        guard let pushNotificationEvent = PinpointEvent.makeEvent(eventSource: eventSource,
                                                                  pushAction: pushAction,
                                                                  usingClient: self.analyticsClient) else {
            log.error("Invalid Pinpoint push notification event.")
            return
        }

        if let identifier = identifier {
            pushNotificationEvent.addAttribute(identifier, forKey: PinpointContext.Constants.Notifications.actionIdentifierKey)
        }

        pushNotificationEvent.addApplicationState()
        pushNotificationEvent.addSourceMetadata(metadata)

        do {
            try await self.analyticsClient.record(pushNotificationEvent)
        } catch {
            log.error("Failed recording event with error \(error)")
        }
    }

    private func remoteNotificationPayload(fromLaunchOptions launchOptions: LaunchOptions) -> UserInfo? {
#if canImport(UIKit)
        return launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? UserInfo
#else
        return nil
#endif
    }

}

// MARK: - AWSPinpointNotifications + metadata helpers
extension AWSPinpointAnalyticsNotifications {
    private func isValidPinpointNotification(payload: UserInfo) -> Bool {
        pinpointPayloadFromNotificationPayload(notification: payload) != nil
    }

    /// Given a Pinpoint notification payload, returns the event source and the metadata associated
    /// - Parameter payload: Pinpoint notification payload
    /// - Returns: the event source (campaign, journey) and its metadata
    private func pinpointMetadata(fromPayload payload: UserInfo) -> (EventSource, [String: Any]?) {
        var metadata: (EventSource, UserInfo?) = (.unknown, nil)

        guard let pinpointPayload = pinpointPayloadFromNotificationPayload(notification: payload) else {
            return metadata
        }

        if let campaignMetadata = pinpointPayload[EventSource.campaign.rawValue] as? UserInfo {
            metadata = (.campaign, campaignMetadata)
            self.log.verbose("Found Pinpoint campaign with attributes: \(campaignMetadata)")

        } else if let journeyMetadata = pinpointPayload[EventSource.journey.rawValue] as? UserInfo {
            metadata = (.journey, journeyMetadata)
            self.log.verbose("Found Pinpoint journey with attributes: \(journeyMetadata)")
        }

        if metadata.1 == nil {
            fatalError("Pinpoint push notification payload not found.")
        }

        return metadata
    }

    private func addGlobalEventSourceMetadata(eventMetadata: UserInfo?,
                                              eventSource: EventSource) async {
        guard let eventMetadata = eventMetadata, !eventMetadata.isEmpty else {
            return
        }

        // Remove previous global event source attributes from _globalAttributes
        // only if event source type changes
        // This is to prevent _globalAttributes containing attributes from multiple event sources (campaign/journey)
        if eventSource != previousEventSource && eventSource != .unknown {
            // remove all global attributes
            await self.analyticsClient.removeAllGlobalEventSourceAttributes()
            previousEventSource = eventSource
        }

        do {
            try await self.analyticsClient.setGlobalEventSourceAttributes(eventMetadata)
        } catch {
            self.log.error("Failed setting event source metadata")
        }

        for (key, value) in eventMetadata {
            guard let value = value as? String else {
                log.debug("Skipping metadata with key \(key) because has a value of type \(type(of: value)).")
                continue
            }
            await self.analyticsClient.addGlobalAttribute(value, forKey: key)
        }

    }
}

// MARK: - AWSPinpointAnalyticsNotifications + handleDeepLink
extension AWSPinpointAnalyticsNotifications {
    typealias CanOpenURL = (URL) -> Bool
    func handleDeepLinkForNotification(userInfo: UserInfo,
                                       canOpenURL: CanOpenURL? = nil) {
#if canImport(UIKit)
        let canOpenURL = canOpenURL ?? UIApplication.shared.canOpenURL
        let openDeepLink = { (url: URL) in UIApplication.shared.open(url) }
#else
        let canOpenURL = canOpenURL ?? { _ in false }
        let openDeepLink = { (url: URL) in  }
#endif

        guard let payload = pinpointPayloadFromNotificationPayload(notification: userInfo) as? [String: String],
              let deepLink = payload[PinpointContext.Constants.Notifications.deeplinkKey],
              let deepLinkURL = URL(string: deepLink) else {
            return
        }
        if canOpenURL(deepLinkURL) {
            DispatchQueue.main.async {
                openDeepLink(deepLinkURL)
            }
        }
    }
}

// MARK: - AWSPinpointAnalyticsNotifications + AWSPinpointPushAction
extension AWSPinpointAnalyticsNotifications {
#if canImport(UIKit)
    func makePinpointPushAction(fromEvent pushEvent: AWSPinpointPushEvent,
                                appState: UIApplication.State = UIApplication.shared.applicationState) -> AWSPinpointPushAction {
        var pushActionType: AWSPinpointPushAction
        switch appState {
        case .active:
            pushActionType = pushEvent == .received ? .receivedForeground : .openedNotification
        case .inactive:
            pushActionType = .openedNotification
        case .background:
            pushActionType = .receivedBackground
        @unknown default:
            pushActionType = .unknown
        }
        return pushActionType
    }
#else
    func makePinpointPushAction(fromEvent pushEvent: AWSPinpointPushEvent) -> AWSPinpointPushAction {
        .unknown
    }
#endif
}

// MARK: - AWSPinpointAnalyticsNotifications + EventSourceType
extension AWSPinpointAnalyticsNotifications {
    /// Pinpoint remote notification event source type (campaign, journey, unknown)
    enum EventSource: String {
        case campaign
        case journey
        case unknown
    }
}

// MARK: - AWSPinpointAnalyticsNotifications + DefaultLogger
extension AWSPinpointAnalyticsNotifications: DefaultLogger {}

// MARK: - AWSPinpointAnalyticsNotifications + areNotificationsEnabled
extension AWSPinpointAnalyticsNotifications {
    static var areNotificationsEnabled: Bool {
        get async {
#if canImport(UIKit)
            let isRegisteredForNotifications = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                DispatchQueue.main.async {
                    let result = UIApplication.shared.isRegisteredForRemoteNotifications
                    continuation.resume(with: .success(result))
                }
            }
            return isRegisteredForNotifications

#else
            // TODO: Update this if needed to support multiplatform
            return false
#endif
        }
    }
}

// MARK: - PinpointEvent + makeWithActionType / addApplicationState
extension PinpointEvent {

    /// Creates a PinpointEvent given an event source and a push notification action.
    /// - Parameters:
    ///   - eventSource: event source
    ///   - pushAction: push notification action
    ///   - analyticClient: analytics client instance
    /// - Returns: a PinpointEvent initialized with the proper event type
    static func makeEvent(eventSource: AWSPinpointAnalyticsNotifications.EventSource,
                          pushAction: AWSPinpointPushAction,
                          usingClient analyticClient: AnalyticsClientBehaviour) -> PinpointEvent? {

        guard pushAction != .unknown else {
            return nil
        }

        let eventPrefix = eventSource.rawValue
        let eventSuffix = pushAction.rawValue
        let eventType = "_\(eventPrefix).\(eventSuffix)"

        return analyticClient.createEvent(withEventType: eventType)
    }

    /// Adds the application state as event attribute on supported platforms.
    func addApplicationState() {
#if canImport(UIKit)
        let appState = UIApplication.shared.applicationState
        let attributeValue: String

        switch appState {
        case .active:
            attributeValue = "UIApplicationStateActive"
        case .inactive:
            attributeValue = "UIApplicationStateInactive"
        case .background:
            attributeValue = "UIApplicationStateBackground"
        @unknown default:
            return
        }

        self.addAttribute(attributeValue,
                          forKey: PinpointContext.Constants.Notifications.attributeApplicationState)
#endif
    }

    func addSourceMetadata(_ metadata: AWSPinpointAnalyticsNotifications.UserInfo?) {
        guard let metadata = metadata else {
            return
        }

        for (key, value) in metadata.compactMap({ $0 as? (String, String) }) {
            self.addAttribute(value, forKey: key)
        }
    }
}

// MARK: - Constants + notifications
extension PinpointContext.Constants {
    enum Notifications {
        static let actionIdentifierKey = "actionIdentifier"
        static let dataKey = "data"
        static let pinpointKey = "pinpoint"
        static let deeplinkKey = "deeplink"
        static let attributeApplicationState = "applicationState"
    }
}

// MARK: - AWSPinpointPushAction
enum AWSPinpointPushAction: String {
    case openedNotification = "opened_notification"
    case receivedForeground = "received_foreground"
    case receivedBackground = "received_background"
    case unknown
}
