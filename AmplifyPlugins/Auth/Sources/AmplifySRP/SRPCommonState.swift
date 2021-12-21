//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit
import AmplifyBigInteger

public struct SRPCommonState {

    /// Group Parameter N of SRP protocol
    public let prime: BigInt

    /// Group Parameter g of SRP protocol
    public let generator: BigInt

    /// SRP-6 multiplier (known as the k Value)
    public let k: BigInt

    public init(prime N: BigInt, generator g: BigInt) {
        self.prime = N
        self.generator = g
        self.k = SRPCommonState.calculateMultiplier(prime: N, generator: g)
    }

    static func calculateMultiplier(prime N: BigInt, generator g: BigInt) -> BigInt {
        let signedBytesN = N.byteArray
        let unSignedBytesg = g.unsignedByteArray

        var digest = SHA256()
        digest.update(data: signedBytesN)
        digest.update(data: unSignedBytesg)
        let hashBytes = [UInt8](digest.finalize())
        return BigInt(unsignedData: hashBytes)
    }
}
