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
import Amplify

public class AWSPinpointAnalyticsNotifications: AWSPinpointAnalyticsNotificationsBehavior {
    private var previousEventSource: EventSource = .unknown
    private let analyticsClient: AnalyticsClientBehaviour
    private let targetingClient: AWSPinpointTargetingClientBehavior
    private let userDefaults: UserDefaultsBehaviour
    
    internal init(analyticsClient: AnalyticsClientBehaviour,
                  targetingClient: AWSPinpointTargetingClientBehavior,
                  userDefaults: UserDefaultsBehaviour) {
        self.analyticsClient = analyticsClient
        self.targetingClient = targetingClient
        self.userDefaults = userDefaults
    }
    
    // MARK: - Public APIs
    public func interceptDidFinishLaunchingWithOptions(launchOptions: LaunchOptions) async -> Bool {
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
    
    public func interceptDidRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data) async {
        let currentToken = self.userDefaults.data(forKey: PinpointContext.Constants.Notifications.deviceTokenKey)
        guard currentToken != deviceToken else {
            return
        }
        
        self.userDefaults.save(deviceToken, forKey: PinpointContext.Constants.Notifications.deviceTokenKey)
        do {
            try await self.targetingClient.updateEndpointProfile()
        } catch {
            log.error("Failed updating endpoint profile with error: \(error)")
        }
    }
    
    public func interceptDidReceiveRemoteNotification(userInfo: UserInfo,
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
    
    private func pinpointMetadata(fromPayload payload: UserInfo) -> (EventSource, UserInfo?) {
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
        
        await self.analyticsClient.setGlobalEventSourceAttributes(eventMetadata)
        
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
                                       canOpenURL: CanOpenURL? = nil){
#if canImport(UIKit)
        let canOpenURL = canOpenURL ?? UIApplication.shared.canOpenURL
#else
        let canOpenURL = canOpenURL ?? {_ in false }
#endif

        guard let payload = pinpointPayloadFromNotificationPayload(notification: userInfo) as? [String: String],
              let deepLink = payload[PinpointContext.Constants.Notifications.deeplinkKey],
              let deepLinkURL = URL(string: deepLink) else {
            return
        }
        if canOpenURL(deepLinkURL) {
            DispatchQueue.main.async {
                UIApplication.shared.open(deepLinkURL)
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
    enum EventSource: String {
        case campaign
        case journey
        case unknown
    }
}

// MARK: - AWSPinpointAnalyticsNotifications + DefaultLogger
extension AWSPinpointAnalyticsNotifications: DefaultLogger {}


// MARK: - PinpointEvent + makeWithActionType / addApplicationState
extension PinpointEvent {
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
        static let deviceTokenKey = "com.amazonaws.AWSDeviceTokenKey"
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

