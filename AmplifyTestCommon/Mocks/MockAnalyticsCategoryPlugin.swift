//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

// `@unchecked Sendable` because the category plugin protocols now require `Sendable` (see
// `Plugin`), and a `Sendable` class may not inherit from a non-`NSObject` superclass. These are
// test doubles driven from a single test at a time.
class MockAnalyticsCategoryPlugin: MessageReporter, AnalyticsCategoryPlugin, @unchecked Sendable {
    var key: String {
        return "MockAnalyticsCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset() {
        notify("reset")
    }

    func disable() {
        notify()
    }

    func enable() {
        notify()
    }

    func identifyUser(userId identityId: String, userProfile analyticsUserProfile: AnalyticsUserProfile?) {
        notify("identifyUser(\(identityId))")
    }

    func record(eventWithName eventName: String) {
        notify("record(eventWithName:\(eventName))")
    }

    func record(event: AnalyticsEvent) {
        notify("record(event:\(event.name))")
    }

    func registerGlobalProperties(_ properties: AnalyticsProperties) {
        notify("registerGlobalProperties")
    }

    func unregisterGlobalProperties(_ keys: Set<String>?) {
        notify()
    }

    func flushEvents() {
        notify()
    }
}

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double.

class MockSecondAnalyticsCategoryPlugin: MockAnalyticsCategoryPlugin, @unchecked Sendable {
    override var key: String {
        return "MockSecondAnalyticsCategoryPlugin"
    }
}
