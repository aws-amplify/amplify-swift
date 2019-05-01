//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Behavior of the Analytics category that clients will use
public protocol AnalyticsCategoryClientBehavior {

    /// Stop sending analytics events. The exact behavior of this API is dependent upon the plugin, but at a minimum,
    /// the plugin must continue to accept analytics `record` events, to be sent when the client issues `enable`.
    func disable()

    /// Begin (or resume) sending analytics events.
    func enable()

    /// A convenience method to allow clients to record an AnalyticsEvent by specifying only the name. Internally, this
    /// method creates a `BasicAnalyticsEvent` with the specified `name` and no attributes or metrics.
    ///
    /// - Parameter name: The name of the event
    func record(_ name: String)

    /// Records an AnalyticsEvent. This method is synchronous, but this protocol does not provide a guarantee of
    /// delivery. Instead, a successful return from this method means that the plugin has accepted the event and will
    /// deliver it according to the rules of that plugin.
    ///
    /// - Parameter event: The AnalyticsEvent to record
    func record(_ event: AnalyticsEvent)

    /// Updates the metrics backend with the analytics profile associated with the current user on the current app
    /// installation. The exact meaning of an "AnalyticsProfile" varies by plugin. For example, in AWSPinpoint, an
    /// AnalyticsProfile maps exactly to an "Endpoint"--a union of user and device that uniquely identifies the user's
    /// installation of your app on their specific device.
    func update(analyticsProfile: AnalyticsProfile)
}

public protocol AnalyticsProfile { }
