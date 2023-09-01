//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(PredictionsFaceLiveness)
public struct CompletedEvent<T> {
    public init(initialEvent: T, endTimestamp: UInt64) {
        self.initialEvent = initialEvent
        self.endTimestamp = endTimestamp
    }

    let initialEvent: T
    let endTimestamp: UInt64
}
