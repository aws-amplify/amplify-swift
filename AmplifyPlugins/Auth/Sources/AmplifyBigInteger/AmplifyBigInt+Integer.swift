//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import libtommath

public extension AmplifyBigInt {

    func add(bigInteger: AmplifyBigInt) -> AmplifyBigInt {
        let sum = AmplifyBigInt()
        _ = mp_add(&value, &bigInteger.value, &sum.value)
        return sum
    }
}

extension AmplifyBigInt: CustomStringConvertible {
    public var description: String {
        asString(radix: 10)
    }
}

