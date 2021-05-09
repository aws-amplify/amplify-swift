//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AnalyticsCategory: AnalyticsCategoryBehavior {

    /// <#Description#>
    /// - Parameters:
    ///   - identityId: <#identityId description#>
    ///   - userProfile: <#userProfile description#>
    public func identifyUser(_ identityId: String, withProfile userProfile: AnalyticsUserProfile? = nil) {
        plugin.identifyUser(identityId, withProfile: userProfile)
    }

    /// <#Description#>
    /// - Parameter event: <#event description#>
    public func record(event: AnalyticsEvent) {
        plugin.record(event: event)
    }

    /// <#Description#>
    /// - Parameter eventName: <#eventName description#>
    public func record(eventWithName eventName: String) {
        plugin.record(eventWithName: eventName)
    }

    /// <#Description#>
    /// - Parameter properties: <#properties description#>
    public func registerGlobalProperties(_ properties: AnalyticsProperties) {
        plugin.registerGlobalProperties(properties)
    }

    /// <#Description#>
    /// - Parameter keys: <#keys description#>
    public func unregisterGlobalProperties(_ keys: Set<String>? = nil) {
        plugin.unregisterGlobalProperties(keys)
    }

    /// <#Description#>
    public func flushEvents() {
        plugin.flushEvents()
    }

    /// <#Description#>
    public func enable() {
        plugin.enable()
    }

    /// <#Description#>
    public func disable() {
        plugin.disable()
    }
}

/// Methods that wrap `AnalyticsCategoryBehavior` to provides additional useful calling patterns
extension AnalyticsCategory {

    /// Registered global properties can be unregistered though this method. In case no keys are provided, *all*
    /// registered global properties will be unregistered. Duplicate keys will be ignored. This method can be called
    /// from `Amplify.Analytics` and is a wrapper for `unregisterGlobalProperties(_ keys: Set<String>? = nil)`
    ///
    /// - Parameter keys: one or more of property names to unregister
    public func unregisterGlobalProperties(_ keys: String...) {
        plugin.unregisterGlobalProperties(keys.isEmpty ? nil : Set<String>(keys))
    }
}
