//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import libtommathAmplify

public extension AmplifyBigInt {

    var bytesCount: Int {
        return Int(amplify_mp_sbin_size(&value))
    }

    var byteArray: [UInt8] {
        let bytesCount = self.bytesCount
        var buffer = [UInt8](repeating: 0, count: bytesCount)
        var written = size_t()
        let error = amplify_mp_to_sbin(&value, &buffer, bytesCount, &written)
        guard error == AMPLIFY_MP_OKAY else {
            fatalError("Could not store to bytes \(error)")
        }
        return buffer
    }

    var unsignedBytesCount: Int {
        return Int(amplify_mp_ubin_size(&value))
    }

    var unsignedByteArray: [UInt8] {
        let bytesCount = unsignedBytesCount
        var buffer = [UInt8](repeating: 0, count: bytesCount)
        var written = size_t()
        let error = amplify_mp_to_ubin(&value, &buffer, bytesCount, &written)
        guard error == AMPLIFY_MP_OKAY else {
            fatalError("Could not store to bytes \(error)")
        }
        return buffer
    }
}
