//
//  File.swift
//  
//
//  Created by Costantino, Diego on 2022-05-31.
//

import Foundation
import Amplify
#if canImport(UIKit)
import UIKit
#endif

class AWSPinpointAnalyticsNotifications: AWSPinpointAnalyticsNotificationsBehavior {
    private static let AWSDataKey = "data"
    private static let AWSPinpointKey = "pinpoint"
    
    private var previousEventSource: EventSource = .unknown
    private let context: PinpointContext
    
    internal init(context: PinpointContext) {
        self.context = context
    }
    
    func interceptDidFinishLaunchingWithOptions(launchOptions: LaunchOptions) -> Bool {
        guard let notificationPayload = remoteNotificationPayload(fromLaunchOptions: launchOptions),
              isValidPinpointNotification(payload: notificationPayload) else {
            return true
        }
        
        let (eventSource, pinpointMetadata) = pinpointMetadata(fromPayload: notificationPayload)
        
        // TODO: record launch because of notification
        
        return true
    }
    
    func interceptDidRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data) {
        
    }
    
    func interceptDidReceiveRemoteNotification(userInfo: UserInfo, pushEvent: AWSPinpointPushEvent) {
        
    }
    
    func interceptDidReceiveRemoteNotification(userInfo: UserInfo, pushEvent: AWSPinpointPushEvent, shouldHandleNotificationDeepLink: Bool) {
        
    }
    
    
    private func isValidPinpointNotification(payload: NotificationMetadata) -> Bool {
        pinpointPayloadFromNotificationPayload(notification: payload) != nil
    }
    
    private func pinpointPayloadFromNotificationPayload(notification: NotificationMetadata) -> [String: Any]? {
        guard let dataPayload = notification[Self.AWSDataKey] as? [String: Any],
              let pinpointMetadata = dataPayload[Self.AWSPinpointKey] as? [String: Any] else {
            return nil
        }
        return pinpointMetadata
    }
    
    private func pinpointMetadata(fromPayload payload: NotificationMetadata) -> (EventSource, NotificationMetadata?) {
        var metadata: (EventSource, NotificationMetadata?) = (.unknown, nil)
        
        guard let pinpointPayload = pinpointPayloadFromNotificationPayload(notification: payload) else {
            return metadata
        }
        
        if let campaignMetadata = pinpointPayload[EventSource.campaign.rawValue] as? NotificationMetadata {
            metadata = (.campaign, campaignMetadata)
            self.log.verbose("Found Pinpoint campaign with attributes: \(campaignMetadata)")
        
        } else if let journeyMetadata = pinpointPayload[EventSource.journey.rawValue] as? NotificationMetadata {
            metadata = (.journey, journeyMetadata)
            self.log.verbose("Found Pinpoint journey with attributes: \(journeyMetadata)")
        }
        
        if metadata.1 == nil {
            fatalError("Pinpoint push payload not found")
        }
        
        return metadata
    }
    
    private func remoteNotificationPayload(fromLaunchOptions launchOptions: LaunchOptions) -> NotificationMetadata? {
#if canImport(UIKit)
        return launchOptions[UIApplication.LaunchOptionsKey.remoteNotification] as? NotificationMetadata
#else
        return nil
#endif
    }
    
    private func addGlobalEventMetadata(eventMetadata: AWSPinpointAnalyticsNotifications.NotificationMetadata?,
                                eventSource: AWSPinpointAnalyticsNotifications.EventSource) {
        guard eventSource != previousEventSource,
              let pinpointMetadata = eventMetadata,
              !pinpointMetadata.isEmpty else {
            return
        }
        previousEventSource = eventSource
        
        // remove all global attributes
        
        // [self.context.analyticsClient setEventSourceAttributes:metadata];
        
        for (key, value) in pinpointMetadata {
            self.context.analyticsClient.addGlobalAttribute(value, forKey: key)
        }
        
    }
}

// MARK: - AWSPinpointNotifications + EventSourceType
extension AWSPinpointAnalyticsNotifications {
    enum EventSource: String {
        case campaign
        case journey
        case unknown
    }
}

// MARK: - AWSPinpointAnalyticsNotifications + DefaultLogger
extension AWSPinpointAnalyticsNotifications: DefaultLogger {}

