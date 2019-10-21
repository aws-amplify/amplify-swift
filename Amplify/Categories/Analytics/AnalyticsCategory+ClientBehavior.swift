//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AnalyticsCategory: AnalyticsCategoryClientBehavior {
    public func identifyUser(_ identityId: String, withProfile userProfile: AnalyticsUserProfile? = nil) {
        plugin.identifyUser(identityId, withProfile: userProfile)
    }

    public func record(event: AnalyticsEvent) {
        plugin.record(event: event)
    }

    public func record(eventWithName eventName: String) {
        plugin.record(eventWithName: eventName)
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
