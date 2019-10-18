//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MockAnalyticsCategoryPlugin: MessageReporter, AnalyticsCategoryPlugin {
    var key: String {
        return "MockAnalyticsCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset(onComplete: @escaping (() -> Void)) {
        notify("reset")
        onComplete()
    }

    func disable() {
        notify()
    }

    func enable() {
        notify()
    }

    func identifyUser(_ identityId: String, analyticsUserProfile: AnalyticsUserProfile?) {
        notify("identifyUser(\(identityId))")
    }

    func record(_ eventName: String) {
        notify("record(\(eventName))")
    }

    func record(_ event: AnalyticsEvent) {
        notify("record(event:\(event.eventName))")
    }

    func registerGlobalProperties(_ properties: [String: AnalyticsPropertyValue]) {
        notify("registerGlobalProperties")
    }

    func unregisterGlobalProperties(_ keys: Set<String>?) {
        notify()
    }

    func flushEvents() {
        notify()
    }
}

class MockSecondAnalyticsCategoryPlugin: MockAnalyticsCategoryPlugin {
    override var key: String {
        return "MockSecondAnalyticsCategoryPlugin"
    }
}
