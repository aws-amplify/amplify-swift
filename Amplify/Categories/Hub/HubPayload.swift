//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A HubPayload is the container for a message dispatched on the Hub
public protocol HubPayload {

}

/// A basic implementation of HubPayload
public struct BasicHubPayload: HubPayload {
    public init() { }
}
