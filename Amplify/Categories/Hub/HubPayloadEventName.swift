//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public typealias HubPayloadEventName = String

/// <#Description#>
public protocol HubPayloadEventNameable {

    /// <#Description#>
    var eventName: HubPayloadEventName { get }
}
