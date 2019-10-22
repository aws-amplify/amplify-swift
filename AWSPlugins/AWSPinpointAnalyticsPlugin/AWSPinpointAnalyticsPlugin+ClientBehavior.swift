//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension AWSPinpointAnalyticsPlugin {
    public func identifyUser(_ identityId: String, withProfile userProfile: AnalyticsUserProfile?) {
    }

    public func record(event: AnalyticsEvent) {
    }

    public func record(eventWithName eventName: String) {
    }

    public func registerGlobalProperties(_ properties: [String: AnalyticsPropertyValue]) {
    }

    public func unregisterGlobalProperties(_ keys: Set<String>?) {
    }

    public func flushEvents() {
    }

    public func enable() {
    }

    public func disable() {
    }
}
