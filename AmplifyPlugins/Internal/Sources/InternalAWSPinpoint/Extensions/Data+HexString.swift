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

        let chars = Array(hexString)
        var bytes = [UInt8]()
        bytes.reserveCapacity(chars.count / 2)
        for i in stride(from: 0, to: chars.count, by: 2) {
            guard let byte = UInt8(String(chars[i]) + String(chars[i + 1]), radix: 16) else {
                return nil
            }
            bytes.append(byte)
        }

        guard !bytes.isEmpty else {
            return nil
        }

        self.init(bytes)
    }

    func asHexString() -> String {
        reduce("") { "\($0)\(String(format: "%02x", $1))" }
    }
}
