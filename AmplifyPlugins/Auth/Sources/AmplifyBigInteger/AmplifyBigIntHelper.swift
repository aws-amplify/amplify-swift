//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AmplifyBigIntHelper {


    /// Converts the signed number into a bytes array.
    /// - Parameter num: The Signed number to be converted
    /// - Returns: Data format for the signed number
    public static func getSignedData(num: AmplifyBigInt) -> [UInt8] {

        let bytesArray = num.byteArray
        let byteCount = bytesArray.count

        // If the sign byte is set, convert to two's complement.
        if byteCount > 1 && bytesArray[0] == 1 {
            var invertedBytes = [UInt8](repeating: 0, count: bytesArray.count)
            invertedBytes[0] = ~invertedBytes[0]
            for i in 1 ..< bytesArray.count {
                invertedBytes[i] = ~bytesArray[i]
            }
            let unsignedInvertedBytes = AmplifyBigInt(unsignedData: invertedBytes)
            let twosComplementNum = unsignedInvertedBytes + AmplifyBigInt(1)
            return twosComplementNum.unsignedByteArray

        } else if byteCount > 1 && bytesArray[1] & 0x80 == 0x80 {
            // Keep the zero sign byte if the most significant bit is set.
            return bytesArray
        }

        // Remove the extra zero
        let result = Array(bytesArray[1...])
        return result

    }
}
