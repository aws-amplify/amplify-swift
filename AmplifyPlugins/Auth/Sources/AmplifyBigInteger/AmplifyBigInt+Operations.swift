//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import libtommath

extension AmplifyBigInt {
    
    // MARK: - Addition
    public static func + (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> AmplifyBigInt {
        let sum = AmplifyBigInt()
        let result = mp_add(&lhs.value, &rhs.value, &sum.value);
        if result != MP_OKAY {
            fatalError("Error occured during + operation: \(result)")
        }
        return sum
    }
    
    public static func + (lhs: AmplifyBigInt, rhs: Int) -> AmplifyBigInt {
        return lhs + AmplifyBigInt(rhs)
    }
    
    public static func + (lhs: Int, rhs: AmplifyBigInt) -> AmplifyBigInt {
        return AmplifyBigInt(lhs) + rhs
    }
    
    public static func += ( lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        lhs = lhs + rhs
    }
    
    public static func += ( lhs: inout AmplifyBigInt, rhs: Int) {
        lhs = lhs + rhs
    }
    
    // MARK: - Subtraction
    
    public static func - (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> AmplifyBigInt {
        let difference = AmplifyBigInt()
        let result = mp_sub(&lhs.value, &rhs.value, &difference.value);
        if result != MP_OKAY {
            fatalError("Error occured during - operation: \(result)")
        }
        return difference
    }
    
    public static func - (lhs: AmplifyBigInt, rhs: Int) -> AmplifyBigInt {
        return lhs - AmplifyBigInt(rhs)
    }
    
    public static func -= ( lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        lhs = lhs - rhs
    }
    
    public static func -= ( lhs: inout AmplifyBigInt, rhs: Int) {
        lhs = lhs - rhs
    }
    
    // MARK: - Multiplication
    
    public static func * (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> AmplifyBigInt {
        let product = AmplifyBigInt()
        let result = mp_mul(&lhs.value, &rhs.value, &product.value);
        if result != MP_OKAY {
            fatalError("Error occured during * operation: \(result)")
        }
        return product
    }
    
    public static func * (lhs: AmplifyBigInt, rhs: Int) -> AmplifyBigInt {
        return lhs * AmplifyBigInt(rhs)
    }
    
    public static func * (lhs: Int, rhs: AmplifyBigInt) -> AmplifyBigInt {
        return rhs * lhs
    }
    
    public static func *= ( lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        lhs = lhs * rhs
    }
    
    public static func *= ( lhs: inout AmplifyBigInt, rhs: Int) {
        lhs = lhs * rhs
    }
    
    // MARK: - Division
    
    public static func / (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> Self {
        fatalError()
    }
    
    public static func /= (lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        fatalError()
    }
    
    public static func % (lhs: AmplifyBigInt, rhs: AmplifyBigInt) -> AmplifyBigInt {
        let quotient = AmplifyBigInt()
        let remainder = AmplifyBigInt()
        
        let result = mp_div(&lhs.value, &rhs.value, &quotient.value, &remainder.value)
        
        if result != MP_OKAY {
            fatalError("Error occured during % operation: \(result)")
        }
        return remainder
    }
    
    
    public static func % (lhs: AmplifyBigInt, rhs: Int) -> AmplifyBigInt {
        return lhs % (AmplifyBigInt(rhs))
    }
    
    public static func %= (lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        lhs = lhs % rhs
    }
    
    // MARK: - Exponentional
    
    public func pow(_ power: AmplifyBigInt,
                    modulus: AmplifyBigInt) -> AmplifyBigInt {
        let exponentialModulus = AmplifyBigInt()
        let result = mp_exptmod(&value, &power.value, &modulus.value, &exponentialModulus.value)
        guard result == MP_OKAY else {
            fatalError("Error occured during pow(:modulus:) operation: \(result)")
        }
        return exponentialModulus
    }
    
    // MARK: - Binary operations

    public static func &= (lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        fatalError()
    }
    
    public static func |= (lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        fatalError()
    }
    
    /// Stores the result of performing a bitwise XOR operation on the two given values in the left-hand-side variable.
    public static func ^= (lhs: inout AmplifyBigInt, rhs: AmplifyBigInt) {
        fatalError()
    }
}
