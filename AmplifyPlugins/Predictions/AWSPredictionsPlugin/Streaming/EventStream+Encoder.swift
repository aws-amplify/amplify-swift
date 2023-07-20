//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import zlib

extension EventStream {
    struct Encoder {
        func encode(payload: Data, headers: [String: HeaderValue]) -> Data {
            var headersLen = 0
            // determine header length by iterating through headers
            for (key, value) in headers {
                headersLen += Data(key.utf8).count
                headersLen += value.headerLengthIncrease
            }

            // length of event stream payload is equivalent to the bytes
            // of the provided playload
            let payloadLength = payload.count

            // create temporary variable to store header length before
            // any mutations.
            let headerLength = headersLen

            // total message length is equivalent to
            //    length of payload (variable)
            //  + length of headers (variable)
            //  + prelude total byte length (constant 4 bytes)
            //  + prelude headers byte length (constant 4 bytes)
            //  + preduce crc (constant 4 bytes)
            //  + message crc (constant 4 bytes)
            let messageLength = 16 + payloadLength + headerLength

            // empty container that will contain the encoded message
            var resultData = Data()

            // total length of message as big endian
            var messageLengthToEncode = UInt32(messageLength).bigEndian

            // retrieve bytes in [UInt8] format
            let messageLengthToEncodeBytes: [UInt8] = withUnsafeBytes(
                of: &messageLengthToEncode,
                Array.init
            )

            // write first 4 bytes [0...3] of the encoded message
            resultData.append(contentsOf: messageLengthToEncodeBytes)

            // length of headers as big endian
            var headerLengthToEncode = UInt32(headerLength).bigEndian

            // retrieves bytes in [UInt8] format
            let headerLengthToEncodeBytes: [UInt8] = withUnsafeBytes(
                of: &headerLengthToEncode,
                Array.init
            )

            // write next 4 bytes [4...7] of the encoded message
            resultData.append(contentsOf: headerLengthToEncodeBytes)

            // extract the first 8 bytes of the encoded message (prelude)
            let preludeData = [UInt8](resultData[0..<8])

            // generate crc based on the prelude
            let crc = crc32(0, preludeData, 8)
            // swap to big endian
            var crcInt = UInt32(crc).bigEndian

            // retrieve bytes in [UInt8] format
            let crcIntBytes: [UInt8] = withUnsafeBytes(of: &crcInt, Array.init)

            // write next 4 bytes [8...11] of the encoded message
            resultData.append(contentsOf: crcIntBytes)

            // iterate through the provided headers to encode them
            // each header is formatted like so:
            // ┌───────────┬───────────────┬──────────┬────────────┬─────────────────┐
            // │Header Name│  Header Name  │  Header  │Value String│                 │
            // │Byte Length│   (String)    │Value Type│ Byte Length│   Value String  │
            // ├───────────┼───────────────┼──────────┼────────────┼─────────────────┤
            // │  1 byte   │Variable Length│  1 byte  │   2 bytes  │ Variable Length │
            // │           │               │          │            │                 │
            // ┗───────────┸───────────────┸──────────┸────────────┸─────────────────┛
            for (key, value) in headers {
                // Header Name Byte Length
                let headerKeyLen: UInt8 = UInt8(Data(key.utf8).count)

                // Value String Byte Length as big endian
                var headerValLen = UInt16(value.data.count).bigEndian
                let headerValLenBytes: [UInt8] = withUnsafeBytes(
                    of: &headerValLen,
                    Array.init
                )

                // write first byte [0] of header
                resultData.append(headerKeyLen)

                // Header Name (String)
                let headerNameData = Data(key.utf8)
                // write [1...n] bytes of header
                resultData.append(contentsOf: headerNameData)

                // Header Value Type
                let headerType: UInt8 = value.headerTypeNumber
                // Write single byte representing header value type
                resultData.append(headerType)

                // if the header type is `byteArray` or `string`,
                // the value length of the header is variable.
                // This means that we need to set the next two bytes
                // with that length.
                //
                // The other (0...5, 8, and 9) have fixed lengths,
                // making it unecessary to specify the length value
                // length bytes
                if headerType == 6 || headerType == 7 {
                    resultData.append(contentsOf: headerValLenBytes)
                }

                // The data representing the header value
                let headerValueData = value.data

                // write the last portion of the header (Value String)
                resultData.append(contentsOf: headerValueData)
            }

            // write the encoded payload portion of the message
            resultData.append(contentsOf: payload)

            // convert to prelude + preludeCRC + header + payload
            // to [UInt8] to generate the message CRC
            let resultDataBytes = [UInt8](resultData)
            // generate message CRC
            let crcMessage = crc32(0, resultDataBytes, uInt(resultDataBytes.count))
            // swap to big endian
            var crcMessageInt = UInt32(crcMessage).bigEndian

            // generate bytes in [UInt] form
            let crcMessageIntBytes: [UInt8] = withUnsafeBytes(
                of: &crcMessageInt,
                Array.init
            )

            // write last 4 bytes of encoded message
            resultData.append(contentsOf: crcMessageIntBytes)

            // assert that the encoded length is equivalent to the expected
            // length determined at the start.
            assert(
                resultData.count == messageLength,
                """
                The encoded data doesn't match the expected byte length
                of the message. This shouldn't happen, please report
                a bug at https://github.com/aws-amplify/amplify-swift
                """
            )

            // fin
            return resultData
        }
    }
}
