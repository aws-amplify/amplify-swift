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

public extension AWSPinpointAnalyticsPlugin {
    func identifyUser(userId: String, userProfile: AnalyticsUserProfile?) {
        if !isEnabled {
            log.warn("Cannot identify user. Analytics is disabled. Call Amplify.Analytics.enable() to enable")
            return
        }

        Task {
            var currentEndpointProfile =  await pinpoint.currentEndpointProfile()
            currentEndpointProfile.addUserId(userId)
            if let userProfile {
                currentEndpointProfile.addUserProfile(userProfile)
            }
            do {
                try await pinpoint.updateEndpoint(
                    with: currentEndpointProfile,
                    source: .analytics
                )
                Amplify.Hub.dispatchIdentifyUser(userId, userProfile: userProfile)
            } catch {
                Amplify.Hub.dispatchIdentifyUser(AnalyticsErrorHelper.getDefaultError(error))
            }
        }
    }

    func record(event: AnalyticsEvent) {
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
                Amplify.Hub.dispatchRecord(pinpointEvent.asAnalyticsEvent())
            } catch {
                Amplify.Hub.dispatchRecord(AnalyticsErrorHelper.getDefaultError(error))
            }
        }
    }

    func record(eventWithName eventName: String) {
        let event = BasicAnalyticsEvent(name: eventName)
        record(event: event)
    }

    func registerGlobalProperties(_ properties: [String: AnalyticsPropertyValue]) {
        // TODO: check if there is a limit on total number of properties
        properties.forEach { key, _ in
            guard key.count >= 1, key.count <= 50 else {
                return Fatal.preconditionFailure("""
                The key `\(key)` is invalid.
                Property keys must have a length from 1 to 50.
                """)
            }
        }
        Task {
            await registerGlobalProperties(properties)
        }
    }

    func unregisterGlobalProperties(_ keys: Set<String>?) {
        Task {
            await unregisterGlobalProperties(keys)
        }
    }

    func flushEvents() {
        if !isEnabled {
            log.warn("Cannot flushEvents. Analytics is disabled. Call Amplify.Analytics.enable() to enable")
            return
        }

        // Do not attempt to submit events if we detect the device is offline, as it's gonna fail anyway
        guard networkMonitor.isOnline else {
            let errorMessage = "Cannot flushEvents. \(AWSPinpointErrorConstants.deviceOffline.errorDescription)"
            log.error(errorMessage)
            Amplify.Hub.dispatchFlushEvents(.unknown(errorMessage))
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

    func enable() {
        isEnabled = true
    }

    func disable() {
        isEnabled = false
    }

    /// Retrieve the escape hatch to perform actions directly on PinpointClient.
    ///
    /// - Returns: PinpointClientProtocol instance
    func getEscapeHatch() -> PinpointClientProtocol {
        pinpoint.pinpointClient
    }

    private func registerGlobalProperties(_ properties: [String: AnalyticsPropertyValue]) async {
        for (key, value) in properties {
            globalProperties[key] = value
            await pinpoint.addGlobalProperty(value, forKey: key)
        }
    }

    private func unregisterGlobalProperties(_ keys: Set<String>?) async {
        guard let keys else {
            for (key, value) in globalProperties {
                await pinpoint.removeGlobalProperty(value, forKey: key)
            }
            globalProperties.removeAll()
            return
        }

        for key in keys {
            if let value = globalProperties[key] {
                await pinpoint.removeGlobalProperty(value, forKey: key)
                globalProperties[key] = nil
            }
        }
    }
}
