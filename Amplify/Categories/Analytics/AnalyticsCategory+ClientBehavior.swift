//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AnalyticsCategory: AnalyticsCategoryClientBehavior {
    public func identifyUser(_ identityId: String, analyticsUserProfile: AnalyticsUserProfile? = nil) {
        plugin.identifyUser(identityId, analyticsUserProfile: analyticsUserProfile)
    }

    public func record(_ analyticsEvent: AnalyticsEvent) {
        plugin.record(analyticsEvent)
    }

    public func record(_ eventName: String) {
        plugin.record(eventName)
    }

    public func registerGlobalProperties(_ properties: [String: AnalyticsPropertyValue]) {
        plugin.registerGlobalProperties(properties)
    }

    public func unregisterGlobalProperties(_ keys: Set<String>? = nil) {
        plugin.unregisterGlobalProperties(keys)
    }

    public func flushEvents() {
        plugin.flushEvents()
    }

    public func enable() {
        plugin.enable()
    }

    public func disable() {
        plugin.disable()
    }
}
