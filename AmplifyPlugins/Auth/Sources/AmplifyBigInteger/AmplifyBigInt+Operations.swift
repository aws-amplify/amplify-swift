//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import libtommathAmplify

public extension AmplifyBigInt {

    // MARK: - Addition
    static func + (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> AmplifyBigInt {
        let sum = AmplifyBigInt()
        let result = amplify_mp_add(&lhs.value, &rhs.value, &sum.value)
        if result != AMPLIFY_MP_OKAY {
            fatalError("Error occured during + operation: \(result)")
        }
        return sum
    }

    static func + (lhs: AmplifyBigInt, rhs: Int) -> AmplifyBigInt {
        return lhs + AmplifyBigInt(rhs)
    }

    static func + (lhs: Int, rhs: AmplifyBigInt) -> AmplifyBigInt {
        return AmplifyBigInt(lhs) + rhs
    }

    static func += ( lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        lhs = lhs + rhs
    }

    static func += ( lhs: inout AmplifyBigInt, rhs: Int) {
        lhs = lhs + rhs
    }

    // MARK: - Subtraction

    static func - (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> AmplifyBigInt {
        let difference = AmplifyBigInt()
        let result = amplify_mp_sub(&lhs.value, &rhs.value, &difference.value)
        if result != AMPLIFY_MP_OKAY {
            fatalError("Error occured during - operation: \(result)")
        }
        return difference
    }

    static func - (lhs: AmplifyBigInt, rhs: Int) -> AmplifyBigInt {
        return lhs - AmplifyBigInt(rhs)
    }

    static func -= ( lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        lhs = lhs - rhs
    }

    static func -= ( lhs: inout AmplifyBigInt, rhs: Int) {
        lhs = lhs - rhs
    }

    // MARK: - Multiplication

    static func * (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> AmplifyBigInt {
        let product = AmplifyBigInt()
        let result = amplify_mp_mul(&lhs.value, &rhs.value, &product.value)
        if result != AMPLIFY_MP_OKAY {
            fatalError("Error occured during * operation: \(result)")
        }
        return product
    }

    static func * (lhs: AmplifyBigInt, rhs: Int) -> AmplifyBigInt {
        return lhs * AmplifyBigInt(rhs)
    }

    static func * (lhs: Int, rhs: AmplifyBigInt) -> AmplifyBigInt {
        return rhs * lhs
    }

    static func *= ( lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        lhs = lhs * rhs
    }

    static func *= ( lhs: inout AmplifyBigInt, rhs: Int) {
        lhs = lhs * rhs
    }

    // MARK: - Division

    static func / (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Self {
        fatalError()
    }

    static func /= (lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        fatalError()
    }

    static func % (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> AmplifyBigInt {
        let quotient = AmplifyBigInt()
        let remainder = AmplifyBigInt()

        let result = amplify_mp_div(&lhs.value, &rhs.value, &quotient.value, &remainder.value)

        if result != AMPLIFY_MP_OKAY {
            fatalError("Error occured during % operation: \(result)")
        }
        return remainder
    }

    static func % (lhs: AmplifyBigInt, rhs: Int) -> AmplifyBigInt {
        return lhs % AmplifyBigInt(rhs)
    }

    static func %= (lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        lhs = lhs % rhs
    }

    // MARK: - Exponentional

    func pow(_ power: AmplifyBigInt,
                    modulus: AmplifyBigInt) -> AmplifyBigInt {
        let exponentialModulus = AmplifyBigInt()
        let result = amplify_mp_exptmod(&value, &power.value, &modulus.value, &exponentialModulus.value)
        guard result == AMPLIFY_MP_OKAY else {
            fatalError("Error occured during pow(:modulus:) operation: \(result)")
        }
        return exponentialModulus
    }

    // MARK: - Binary operations

    static func &= (lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        fatalError()
    }

    static func |= (lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        fatalError()
    }

    /// Stores the result of performing a bitwise XOR operation on the two given values in the left-hand-side variable.
    static func ^= (lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        fatalError()
    }
}
