//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

final public class AnalyticsCategory: BaseCategory<CategoryMarker.Analytics, AnyAnalyticsCategoryPlugin> { }

extension AnalyticsCategory: AnalyticsCategoryClientBehavior {
    public func disable() {
        defaultPlugin.disable()
    }

    public func enable() {
        defaultPlugin.enable()
    }

    public func record(_ name: String) {
        defaultPlugin.record(name)
    }

    public func record(_ event: AnalyticsEvent) {
        defaultPlugin.record(event)
    }

    public func update(analyticsProfile: AnalyticsProfile) {
        defaultPlugin.update(analyticsProfile: analyticsProfile)
    }

}
