//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

extension AWSPinpointAnalyticsPlugin {
    public func identifyUser(_ identityId: String, withProfile userProfile: AnalyticsUserProfile?) {
        if !isEnabled {
            log.warn("Cannot identify user. Analytics is disabled. Call Amplify.Analytics.enable() to enable")
            return
        }

        Task {
            let currentEndpointProfile =  await pinpoint.currentEndpointProfile()
            currentEndpointProfile.addIdentityId(identityId)
            if let userProfile = userProfile {
                currentEndpointProfile.addUserProfile(userProfile)
            }
            do {
                try await pinpoint.update(currentEndpointProfile)
                Amplify.Hub.dispatchIdentifyUser(identityId, userProfile: userProfile)
            } catch {
                Amplify.Hub.dispatchIdentifyUser(AnalyticsErrorHelper.getDefaultError(error))
            }
        }
    }

    public func record(event: AnalyticsEvent) {
        if !isEnabled {
            log.warn("Cannot record events. Analytics is disabled. Call Amplify.Analytics.enable() to enable")
            return
        }

        let pinpointEvent = pinpoint.createEvent(withEventType: event.name)

        if let properties = event.properties {
            pinpointEvent.addProperties(properties)
        }

        Task {
            do {
                try await pinpoint.record(pinpointEvent)
                Amplify.Hub.dispatchRecord(event)
            } catch {
                Amplify.Hub.dispatchRecord(AnalyticsErrorHelper.getDefaultError(error))
            }
        }
    }

    public func record(eventWithName eventName: String) {
        let event = BasicAnalyticsEvent(name: eventName)
        record(event: event)
    }

    public func registerGlobalProperties(_ properties: [String: AnalyticsPropertyValue]) {
        // TODO: check if there is a limit on total number of properties
        properties.forEach { key, _ in
            guard key.count >= 1, key.count <= 50 else {
                return Fatal.preconditionFailure("""
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
            log.warn("Cannot flushEvents. Analytics is disabled. Call Amplify.Analytics.enable() to enable")
            return
        }

        Task {
            do {
                let submittedEvents = try await pinpoint.submitEvents().asAnalyticsEventArray()
                Amplify.Hub.dispatchFlushEvents(submittedEvents)
            } catch {
                Amplify.Hub.dispatchFlushEvents(AnalyticsErrorHelper.getDefaultError(error))
            }
        }
    }

    public func enable() {
        isEnabled = true
    }

    public func disable() {
        isEnabled = false
    }

    /// Retrieve the escape hatch to perform actions directly on PinpointClient.
    ///
    /// - Returns: AWSPinpoint instance
    public func getEscapeHatch() -> AWSPinpoint {
        pinpoint.getEscapeHatch()
    }
}
