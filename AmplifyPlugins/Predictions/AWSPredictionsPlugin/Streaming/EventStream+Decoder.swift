//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import zlib

extension EventStream {
    struct Decoder {
        /// Decode data into a Message conformant to `EventStream`
        ///
        /// The payload itself is not decoded as part of this process.
        /// It's returned as `Data` in the `payload` property of `Message`.
        /// This is because the caller often doesn't know which type the payload should
        /// be decoded into until it inspects the header values.
        ///
        /// - Parameter data: data to be decoded.
        /// - Returns: A decoded message.
        /// - Precondition: `data.count >= 16`
        func decode(data: Data) throws -> Message {
            assert(
                data.count >= 16,
                """
                Decoding requires at least 16 bytes.
                Provided data contains \(data.count) bytes
                """
            )

            // Create a mutable slice of the entire (`UnboundedRange_`)
            // data provided for decoding.
            // This lets us remove the decoded bytes while each
            // portion as we no longer need them.
            var data = data[...]

            // determine the total length of the message
            // from the first 4 bytes.
            let totalByteLength: Int32 = try Data(data.readBytes(count: 4))
                .bigEndianFixedWidth()

            // determine the length of the headers from
            // the next 4 bytes.
            let headerByteLength: Int32 = try Data(data.readBytes(count: 4))
                .bigEndianFixedWidth()

            // get the CRC of the prelude (total length + headers length)
            let preludeCRC: Int32 = try Data(data.readBytes(count: 4))
                .bigEndianFixedWidth()

            // bytes of all headers determined by the headerByteLength
            let headerBytes = Data(
                try data.readBytes(
                    count: Int(headerByteLength)
                )
            )

            // decode headers in [Header]
            let headers = try headers(from: headerBytes)

            // bytes of the payload
            // variable length based on total length - constant length - headers length
            let payloadBytes = Data(try data.readBytes(count: data.count - 4))

            // last 4 bytes of messagee make up the CRC for the whole message.
            let messageCRC: Int32 = Data(data).bigEndianFixedWidth()

            let message = Message(
                totalByteLength: totalByteLength,
                headersByteLength: headerByteLength,
                preludeCRC: preludeCRC,
                headers: headers,
                payload: payloadBytes,
                messageCRC: messageCRC
            )

            return message
        }


        private func headers(from data: Data) throws -> [Header] {
            // Create a mutable slice of the entire (`UnboundedRange_`)
            // data provided for decoding.
            // This lets us remove the decoded bytes while each
            // portion as we no longer need them.
            var data = data[...]

            var headers = [Header]()

            // We're consuming the bytes as we're decoding.
            // If the data is malformed, we'll hit an error
            // in one of the decoding processes. Therefore
            // there's no risk of an infinite while loop here.
            while data.count > 0 {
                // Despite this being a single byte (UInt8), we're converted it
                // to an Int to prevent the need for multiple transformations.
                // It's data representation is unimportant for the decoding
                // process.
                let nameByteLength = try Int(data.readByte())

                // Variable length based on `nameByteLength`. These
                // bytes make up the name / key of the header.
                let nameBytes = try data.readBytes(count: nameByteLength)

                // Decode nameBytes into UTF8 String.
                let name = String(
                    decoding: nameBytes,
                    as: UTF8.self
                )

                // The next byte represents the value type of the header.
                // This could theoritically be one of 9 different value types outlined
                // in the `EventStream` documentation.
                // In practice, this is limited to String.
                // Any transformations from String to the specified `valueType`
                // are exercises left to the caller.
                let valueTypeByte = try data.readByte()

                // Despite only using this value for informational purposes
                // as outlined above, the spec specifies valid valueTypes
                // as 0...9. If this provided byte doesn't fulfill this requirement
                // we're throwing and exiting.
                guard let valueType = EventStream.Header.ValueType(
                    rawValue: valueTypeByte
                ) else {
                    throw HeaderValueDecodingError(
                        description: """
                        Invalid value type. Expected byte 0...9.
                        """,
                        valueTypeCode: valueTypeByte,
                        data: data
                    )
                }

                // The next 2 bytes represent the length of the header value
                let valueLength: Int16 = try Data(data.readBytes(count: 2))
                    .bigEndianFixedWidth()

                let headerValueBytes = Data(try data.readBytes(count: Int(valueLength)))
                let headerValue = String(decoding: headerValueBytes, as: UTF8.self)

                let header = Header(
                    nameByteLength: nameByteLength,
                    name: name,
                    valueType: valueType,
                    valueByteLength: valueLength,
                    value: headerValue
                )

                headers.append(header)
            }
            return headers
        }

        struct HeaderValueDecodingError: Error {
            let description: String
            let valueTypeCode: UInt8
            let data: Data
        }
    }
}

fileprivate extension Data {
    func bigEndianFixedWidth<T: FixedWidthInteger>(_ type: T.Type = T.self) -> T {
        self.withUnsafeBytes { $0.load(as: type) }.bigEndian
    }
}


/**
 Time Profiling

     » cat reversed.swift
     import Foundation

     for _ in (1...500_000) {
        _ = Data.init(count: 100)[0...3]
            .reversed()
            .withUnsafeBytes { $0.load(as: Int32.self) }
     }

     » cat byteSwapped.swift
     import Foundation

     for _ in (1...500_000) {
        _ = Data.init(count: 100)[0...3]
            .withUnsafeBytes { $0.load(as: Int32.self) }
            .byteSwapped
     }

     » cat bigEndian.swift
     import Foundation

     for _ in (1...500_000) {
        _ = Data.init(count: 100)[0...3]
            .withUnsafeBytes { $0.load(as: Int32.self) }
            .bigEndian
     }

     » swiftc -o reversed -O reversed.swift
     » swiftc -o byteswapped -O byteSwapped.swift
     » swiftc -o bigendian -O bigEndian.swift

     » time ./reversed
     ./reversed  0.10s user 0.00s system 64% cpu 0.168 total

     » time ./byteswapped
     ./byteswapped  0.05s user 0.01s system 21% cpu 0.290 total

     » time ./bigendian
     ./bigendian  0.06s user 0.01s system 22% cpu 0.283 total


 - Note: `Int(n).bigEndian` checks the endianness of the system through a
 conditional compilation block. If it's big, it returns self. If not, it does a `byteSwapped`.
 While we _could_ use `byteSwapped` directly because  we only support little endian platforms (today),
 there's not additional runtime cost to uses `bigEndian` and it is less fragile.
 */
