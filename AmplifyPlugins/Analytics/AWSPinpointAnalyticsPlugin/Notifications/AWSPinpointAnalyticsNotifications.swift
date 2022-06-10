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
    private let context: PinpointContext
    
    internal init(context: PinpointContext) {
        self.context = context
    }
    
    // MARK: - Public APIs
    public func interceptDidFinishLaunchingWithOptions(launchOptions: LaunchOptions) -> Bool {
        guard let notificationPayload = remoteNotificationPayload(fromLaunchOptions: launchOptions),
              isValidPinpointNotification(payload: notificationPayload) else {
            return true
        }
        
        let (eventSource, pinpointMetadata) = pinpointMetadata(fromPayload: notificationPayload)
        Task {
            await self.addGlobalEventMetadata(eventMetadata: pinpointMetadata, eventSource: eventSource)
            recordEventForNotification(eventSource: eventSource,
                                       pushEvent: .opened,
                                       pushAction: .openedNotification)
        }
        
        return true
    }
    
    public func interceptDidRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data) {
        let currentToken = self.context.userDefaults.data(forKey: PinpointContext.Constants.Notifications.deviceTokenKey)
        guard currentToken != deviceToken else {
            return
        }
        
        self.context.userDefaults.save(deviceToken, forKey: PinpointContext.Constants.Notifications.deviceTokenKey)
        Task {
            do {
                try await self.context.targetingClient.updateEndpointProfile()
            } catch {
                log.error("Failed updating endpoint profile with error: \(error)")
            }
        }
    }
    
    public func interceptDidReceiveRemoteNotification(userInfo: UserInfo,
                                                      pushEvent: AWSPinpointPushEvent = .received,
                                                      shouldHandleNotificationDeepLink: Bool) {
        let (eventSource, metadata) = pinpointMetadata(fromPayload: userInfo)
        let pushAction = makePinpointPushAction(fromEvent: pushEvent)
        
        switch pushAction {
        case .openedNotification:
            log.verbose("App launched from received notification.")
            Task {
                await self.addGlobalEventMetadata(eventMetadata: metadata, eventSource: eventSource)
                self.recordEventForNotification(eventSource: eventSource, pushEvent: .opened, pushAction: pushAction)
                
                if shouldHandleNotificationDeepLink {
                    self.handleDeepLinkForNotification(userInfo: userInfo)
                }
            }
            
        case .receivedBackground:
            log.verbose("Received notification with app in background.")
            Task {
                await self.addGlobalEventMetadata(eventMetadata: metadata, eventSource: eventSource)
                self.recordEventForNotification(eventSource: eventSource, pushEvent: .received, pushAction: pushAction)
            }
        
        case .receivedForeground:
            log.verbose("Received notification with app in foreground.")
            
            // Not adding global event source metadata because if the app session is already running,
            // the session should not contribute to the new push notification that is being received
            self.recordEventForNotification(eventSource: eventSource, pushEvent: .received, pushAction: pushAction)
        
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
    
    private func recordEventForNotification(eventSource: EventSource,
                                            pushEvent: AWSPinpointPushEvent,
                                            pushAction: AWSPinpointPushAction,
                                            withIdentifier identifier: String? = nil) {
        guard let pushNotificationEvent = PinpointEvent.makeEvent(eventSource: eventSource,
                                                                  pushAction: pushAction,
                                                                  usingClient: self.context.analyticsClient) else {
            log.error("Invalid Pinpoint push notification event.")
            return
        }
        
        if let identifier = identifier {
            pushNotificationEvent.addAttribute(identifier, forKey: PinpointContext.Constants.Notifications.actionIdentifierKey)
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
    
    private func addGlobalEventMetadata(eventMetadata: UserInfo?,
                                        eventSource: EventSource) async {
        guard eventSource != previousEventSource,
              let pinpointMetadata = eventMetadata,
              !pinpointMetadata.isEmpty else {
            return
        }
        previousEventSource = eventSource
        
        // remove all global attributes
        
        // [self.context.analyticsClient setEventSourceAttributes:metadata];
        
        for (key, value) in pinpointMetadata {
            guard let value = value as? String, let key = key as? String else {
                log.debug("Skipping metadata with key \(key) because has value of type \(type(of: value)).")
                continue
            }
            await self.context.analyticsClient.addGlobalAttribute(value, forKey: key)
        }
        
    }
}

// MARK - AWSPinpointAnalyticsNotifications + handleDeepLink
extension AWSPinpointAnalyticsNotifications {
    func handleDeepLinkForNotification(userInfo: UserInfo) {
        guard let payload = pinpointPayloadFromNotificationPayload(notification: userInfo) as? [String: String],
              let deepLink = payload[PinpointContext.Constants.Notifications.deeplinkKey],
              let deepLinkURL = URL(string: deepLink) else {
            return
        }
        
#if canImport(UIKit)
        if UIApplication.shared.canOpenURL(deepLinkURL) {
            DispatchQueue.main.async {
                UIApplication.shared.open(deepLinkURL)
            }
        }
#endif
        
    }
}

// MARK: - AWSPinpointAnalyticsNotifications + AWSPinpointPushAction
extension AWSPinpointAnalyticsNotifications {
    func makePinpointPushAction(fromEvent pushEvent: AWSPinpointPushEvent) -> AWSPinpointPushAction {
        var pushActionType: AWSPinpointPushAction

#if canImport(UIKit)
        let appState = UIApplication.shared.applicationState
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
#else
        pushActionType = .unknown
#endif
        return pushActionType
    }
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


// MARK: - PinpointEvent + makeWithActionType
extension PinpointEvent {
    static func makeEvent(eventSource: AWSPinpointAnalyticsNotifications.EventSource,
                          pushAction: AWSPinpointPushAction,
                          usingClient analyticClient: AnalyticsClient) -> PinpointEvent? {
        
        guard pushAction != .unknown else {
            return nil
        }
        
        let eventPrefix = eventSource.rawValue
        let eventSuffix = pushAction.rawValue
        let eventType = "_\(eventPrefix).\(eventSuffix)"
        
        return analyticClient.createEvent(withEventType: eventType)
    }
}


// MARK: - Constants + notifications
fileprivate extension PinpointContext.Constants {
    enum Notifications {
        static let actionIdentifierKey = "actionIdentifier"
        static let deviceTokenKey = "com.amazonaws.AWSDeviceTokenKey"
        static let dataKey = "data"
        static let pinpointKey = "pinpoint"
        static let deeplinkKey = "deeplink"
    }
}

// MARK: - AWSPinpointPushAction
enum AWSPinpointPushAction: String {
    case openedNotification = "opened_notification"
    case receivedForeground = "received_foreground"
    case receivedBackground = "received_background"
    case unknown
}

