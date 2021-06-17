//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Age range of an entity(faces/celebrities) detected
/// as a result of identify() API
public struct AgeRange {
    public let low: Int
    public let high: Int

    public init(low: Int, high: Int) {
        self.low = low
        self.high = high
    }
}
