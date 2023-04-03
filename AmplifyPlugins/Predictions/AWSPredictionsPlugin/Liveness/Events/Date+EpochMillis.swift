//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Date {
    var epochMilliseconds: UInt64 {
        UInt64(self.timeIntervalSince1970 * 1_000)
    }
}
