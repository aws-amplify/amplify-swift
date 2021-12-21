//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import libtommath

extension AmplifyBigInt {
    
    public var bytesCount: Int {
        return Int(mp_sbin_size(&self.value))
    }
    
    public var byteArray: [UInt8] {
        let bytesCount = self.bytesCount
        var buffer = [UInt8](repeating: 0, count: bytesCount)
        var written = size_t()
        let error = mp_to_sbin(&value, &buffer, bytesCount, &written)
        guard error == MP_OKAY else {
            fatalError("Could not store to bytes \(error)")
        }
        return buffer
    }
    
    public var unsignedBytesCount: Int {
        return Int(mp_ubin_size(&self.value))
    }
    
    public var unsignedByteArray: [UInt8] {
        let bytesCount = self.unsignedBytesCount
        var buffer = [UInt8](repeating: 0, count: bytesCount)
        var written = size_t()
        let error = mp_to_ubin(&value, &buffer, bytesCount, &written)
        guard error == MP_OKAY else {
            fatalError("Could not store to bytes \(error)")
        }
        return buffer
    }
}
