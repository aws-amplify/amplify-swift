//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension TimeInterval {
    /// Creates a `TimeInterval` with a value equal to the number of minutes * 60
    static func minutes(_ minutes: Double) -> TimeInterval {
        minutes * 60.0
    }
}
