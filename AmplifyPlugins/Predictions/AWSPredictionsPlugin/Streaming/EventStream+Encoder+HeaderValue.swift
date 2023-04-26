//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension EventStream {
    struct HeaderValue {
        let data: Data
        let headerTypeNumber: UInt8
        let headerLengthIncrease: Int

        static func string(_ value: String) -> HeaderValue {
            let data = Data(value.utf8)
            return .init(
                // string value in `utf8` encoded format
                data: data,
                // string
                headerTypeNumber: 7,
                // for string, the header length increase is
                // is the byte count of the utf8 encoded string (variable)
                // + Header Name Byte Length (1 byte)
                // + Header Value Type (1 byte)
                // + Value Byte Length (2 bytes)
                headerLengthIncrease: data.count + 4
            )
        }

        static func data(_ value: Data) -> HeaderValue {
            .init(
                data: value,
                // data (a.k.a. ByteArray)
                headerTypeNumber: 6,
                // for data, the header length increase is
                // is the byte count of the data (variable)
                // + Header Name Byte Length (1 byte)
                // + Header Value Type (1 byte)
                // + Value Byte Length (2 bytes)
                headerLengthIncrease: value.count + 4
            )
        }

        static func timestamp(_ value: Date) -> HeaderValue {
            // get epoch in milliseconds and swap to big endian
            var timestampMillis = UInt64(value.timeIntervalSince1970 * 1_000).byteSwapped

            // convert timestamp to `Data`
            let timestampData = Data(
                bytes: &timestampMillis,
                count: MemoryLayout<UInt64>.size
            )

            return .init(
                data: timestampData,
                // timestamp headers are represented by the number 8
                headerTypeNumber: 8,
                // for timestamps, the constant portion of the header size
                // is the size of the timestamp (8 bytes) +
                // Header Name Byte Length (1 byte) +
                // Header Value Type (1 byte)
                //
                // Value String Byte Length (2 bytes) must not
                // be included because timestamp has a constant size.
                headerLengthIncrease: 8 + 2
            )
        }
    }
}

extension EventStream.HeaderValue: ExpressibleByStringLiteral {
    init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}
