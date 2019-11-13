//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPinpoint

extension AWSPinpointAnalyticsPlugin {
    public func identifyUser(_ identityId: String, withProfile userProfile: AnalyticsUserProfile?) {
        if !isEnabled {
            amplifyLogging("Cannot identify user. Analytics is disabled. Call Amplify.Analytics.enable() to enable")
            return
        }

        let currentEndpointProfile = pinpoint.currentEndpointProfile()
        currentEndpointProfile.addIdentityId(identityId)
        if let userProfile = userProfile {
            if userProfile.location == nil {
                // TODO: Check if location is set, if it is not set,
                // see if we can populate it ourselves before adding it.
            }

            currentEndpointProfile.addUserProfile(userProfile)
        }

        pinpoint.update(currentEndpointProfile).continueWith { (task) -> Any? in
            guard task.error == nil else {
                // TODO: some error mapping
                let error = task.error! as NSError
                Amplify.Hub.dispatchIdentifyUser(AnalyticsErrorHelper.getDefaultError(error))
                return nil
            }

            Amplify.Hub.dispatchIdentifyUser(identityId, userProfile: userProfile)
            return nil
        }
    }

    public func record(event: AnalyticsEvent) {
        if !isEnabled {
            amplifyLogging("Cannot record events. Analytics is disabled. Call Amplify.Analytics.enable() to enable")
            return
        }

        let pinpointEvent = pinpoint.createEvent(withEventType: event.name)

        if let properties = event.properties {
            pinpointEvent.addProperties(properties)
        }

        pinpoint.record(pinpointEvent).continueWith { (task) -> Any? in
            guard task.error == nil else {
                // TODO: some error mapping
                let error = task.error! as NSError
                Amplify.Hub.dispatchRecord(AnalyticsErrorHelper.getDefaultError(error))
                return nil
            }

            Amplify.Hub.dispatchRecord(event)
            return nil
        }
    }

    public func record(eventWithName eventName: String) {
        let event = BasicAnalyticsEvent(eventName)
        record(event: event)
    }

    public func registerGlobalProperties(_ properties: [String: AnalyticsPropertyValue]) {
        // TODO: check if there is a limit on total number of properties
        properties.forEach { key, _ in
            guard key.count >= 1, key.count <= 50 else {
                preconditionFailure("""
                                    The key `\(key)` is invalid.
                                    Property keys must have a length from 1 to 50.
                                    """)
            }
        }

        properties.forEach { key, newValue in
            globalProperties.updateValue(newValue, forKey: key)
            pinpoint.addGlobalProperty(withValue: newValue, forKey: key)
        }

    }

    public func unregisterGlobalProperties(_ keys: Set<String>?) {
        guard let keys = keys else {
            globalProperties.forEach { key, value in
                pinpoint.removeGlobalProperty(withValue: value, forKey: key)
            }
            globalProperties.removeAll()

            return
        }

        keys.forEach { key in
            if let value = globalProperties[key] {
                pinpoint.removeGlobalProperty(withValue: value, forKey: key)
                globalProperties.removeValue(forKey: key)
            }
        }
    }

    public func flushEvents() {
        if !isEnabled {
            amplifyLogging("Cannot flushEvents. Analytics is disabled. Call Amplify.Analytics.enable() to enable")
            return
        }

        pinpoint.submitEvents().continueWith { (task) -> Any? in
            guard task.error == nil else {
                // TODO: some error mapping
                let error = task.error! as NSError
                Amplify.Hub.dispatchFlushEvents(AnalyticsErrorHelper.getDefaultError(error))
                return nil
            }

            if let pinpointEvents = task.result as? [AWSPinpointEvent] {
                // TODO: revist this, this is exposing internal implementation
                Amplify.Hub.dispatchFlushEvents(pinpointEvents)
            }

            return nil
        }
    }

    public func enable() {
        isEnabled = true
    }

    public func disable() {
        isEnabled = false
    }

    // TODO: replace this with Amplify.Logging
    private func amplifyLogging(_ message: String) {
        print(message)
    }
}
