//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPinpoint
import Foundation

extension HubCategory {
    func dispatchIdentifyUser(_ identityId: String, userProfile: UserProfile?) {
        let payload = HubPayload(eventName: HubPayload.EventName.Analytics.identifyUser,
                                 data: (identityId, userProfile))
        dispatch(to: .analytics, payload: payload)
    }

    func dispatchIdentifyUser(_ error: AnalyticsError) {
        let payload = HubPayload(eventName: HubPayload.EventName.Analytics.identifyUser, data: error)
        dispatch(to: .analytics, payload: payload)
    }

    func dispatchRecord(_ event: AnalyticsEvent) {
        let payload = HubPayload(eventName: HubPayload.EventName.Analytics.record, data: event)
        dispatch(to: .analytics, payload: payload)
    }

    func dispatchRecord(_ error: AnalyticsError) {
        let payload = HubPayload(eventName: HubPayload.EventName.Analytics.record, data: error)
        dispatch(to: .analytics, payload: payload)
    }

    func dispatchFlushEvents(_ pinpointEvents: [AnalyticsEvent]) {
        let payload = HubPayload(eventName: HubPayload.EventName.Analytics.flushEvents, data: pinpointEvents)
        dispatch(to: .analytics, payload: payload)
    }

    func dispatchFlushEvents(_ error: AnalyticsError) {
        let payload = HubPayload(eventName: HubPayload.EventName.Analytics.flushEvents, data: error)
        dispatch(to: .analytics, payload: payload)
    }
}
