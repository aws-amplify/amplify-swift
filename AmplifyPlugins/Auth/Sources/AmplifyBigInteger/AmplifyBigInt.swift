//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import libtommathAmplify


public final class AmplifyBigInt {

    var value = amplify_mp_int(used: 0, alloc: 0, sign: AMPLIFY_MP_ZPOS, dp: nil)

    public init() {

    }

    public init?(_ numericString: String, radix: Int = 10) {
        if radix < 2 || radix > 36 {
            print("Error in creating BigInt, radix is out of range")
            return nil
        }
        let uppercasedValue = numericString.uppercased()
        let cString = uppercasedValue.cString(using: .utf8)
        let error = amplify_mp_read_radix(&value, cString, Int32(radix))
        if error != AMPLIFY_MP_OKAY {
            print("Error in creating BigInt - \(error)")
            return nil
        }
    }

    public convenience init?(_ numericString: String) {
        self.init(numericString, radix: 10)
    }

    /// Creates a signed big integer from the bytes provided
    ///
    /// The first byte determine the sign of the number, if the first byte is
    /// 0 == positive or 1 == negative.
    /// - Parameter data: bytes to represent as signed number
    public init(_ data: [UInt8]) {
        let error = amplify_mp_from_sbin(&value, data, data.count)
        guard error == AMPLIFY_MP_OKAY else {
            fatalError("Could not create a signed number from data - \(error)")
        }
    }

    /// Creates a un-signed big integer from the bytes provided
    ///
    /// - Parameter data: bytes to represent as un-signed number
    public init(unsignedData data: [UInt8]) {
        let error = amplify_mp_from_ubin(&value, data, data.count)
        guard error == AMPLIFY_MP_OKAY else {
            fatalError("Could not create a signed number from data - \(error)")
        }
    }

    public required convenience init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }

    public convenience init(_ int: Int) {
        self.init("\(int)")!
    }

    deinit {
        amplify_mp_clear(&value)
    }

    public var asString: String {
        return self.asString(radix: 10)
    }

    public func asString(radix: Int = 10) -> String {
        // Will be replaced with this method - https://developer.apple.com/documentation/swift/string/2997127-init
        // when moving to `BinaryInteger` conformance.
        if radix < 2 || radix > 36 {
            fatalError("Could not convert to string, radix is out of range")
        }
        var stringLength = Int32()
        let lengthResult = amplify_mp_radix_size(&value, Int32(radix), &stringLength)
        guard lengthResult == AMPLIFY_MP_OKAY else {
            fatalError("Could not find the size of the string to represent - \(lengthResult)")
        }
        let stringLengthInt = Int(stringLength)
        var cString = [Int8](repeating: 0, count: stringLengthInt)
        var written = size_t()
        let conversionResult = amplify_mp_to_radix(&value, &cString, stringLengthInt, &written, Int32(radix))
        guard conversionResult == AMPLIFY_MP_OKAY else {
            fatalError("Could not convert to string - \(conversionResult)")
        }

        return String(cString: cString)
    }
}

enum AmplifyBigIntError: Error {

    case conversion(amplify_mp_err)
}
