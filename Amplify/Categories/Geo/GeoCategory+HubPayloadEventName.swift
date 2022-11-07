//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension HubPayload.EventName {
    /// Geo hub events
    struct Geo { }
}

public extension HubPayload.EventName.Geo {
    static let saveLocationsFailed = "Geo.saveLocationsFailed"
}
