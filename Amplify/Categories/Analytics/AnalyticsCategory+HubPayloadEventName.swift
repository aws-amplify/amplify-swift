//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension HubPayload.EventName {

    /// <#Description#>
    struct Analytics { }
}

public extension HubPayload.EventName.Analytics {

    /// <#Description#>
    static let identifyUser = "Analytics.identifyUser"

    /// <#Description#>
    static let record = "Analytics.record"

    /// <#Description#>
    static let flushEvents = "Analytics.flushEvents"
}
