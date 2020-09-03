//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Used as HubPayload for the `OutboxStatus`
public struct OutboxStatusEvent {
    public let isEmpty: Bool /// status of outbox: empty or not

    public init(isEmpty: Bool) {
        self.isEmpty = isEmpty
    }
}
