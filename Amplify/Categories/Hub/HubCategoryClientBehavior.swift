//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Behavior of the Auth category that clients will use
public protocol HubCategoryClientBehavior {
    func dispatch(to channel: HubChannel, payload: HubPayload)
}
