//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Data {
    init?(hexString: String) {
        guard hexString.count.isMultiple(of: 2) else {
            return nil
        }

        let chars = hexString.map { $0 }
        let bytes = stride(from: 0, to: chars.count, by: 2)
            .map { String(chars[$0]) + String(chars[$0 + 1]) }
            .compactMap { UInt8($0, radix: 16) }

        guard hexString.count / bytes.count == 2 else {
            return nil
        }

        self.init(bytes)
    }

    func asHexString() -> String {
        reduce("") { "\($0)\(String(format: "%02x", $1))" }
    }
}
