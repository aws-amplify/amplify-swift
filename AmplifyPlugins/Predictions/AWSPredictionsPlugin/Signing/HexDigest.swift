//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Sequence where Element == UInt8 {
    func hexDigest() -> String {
        map { String(format: "%02x", $0) }.joined()
    }
}
