//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven
// by a single test at a time.
class NotificationListeningAnalyticsPlugin: AnalyticsCategoryPlugin, @unchecked Sendable {
    let key = "NotificationListeningAnalyticsPlugin"
    let notificationReceived: XCTestExpectation

    init(notificationReceived: XCTestExpectation) {
        self.notificationReceived = notificationReceived
    }

    func configure(using configuration: Any?) throws {
        let isConfigured = HubFilters.forEventName(HubPayload.EventName.Amplify.configured)

        var token: UnsubscribeToken?
        token = Amplify.Hub.listen(to: .analytics, isIncluded: isConfigured) { _ in
            self.notificationReceived.fulfill()
            if let token {
                Amplify.Hub.removeListener(token)
            }
        }
    }

    func identifyUser(userId identityId: String, userProfile: AnalyticsUserProfile?) {
        // Do nothing
    }

    func record(event: AnalyticsEvent) {
        // Do nothing
    }

    func record(eventWithName eventName: String) {
        // Do nothing
    }

    func registerGlobalProperties(_ properties: AnalyticsProperties) {
        // Do nothing
    }

    func unregisterGlobalProperties(_ keys: Set<String>?) {
        // Do nothing
    }

    func flushEvents() {
        // Do nothing
    }

    func enable() {
        // Do nothing
    }

    func disable() {
        // Do nothing
    }

    func reset() {
        // Do nothing
    }

}
