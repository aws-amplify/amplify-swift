//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension EventStream {
    /// Utility type used for encoding and decoding request conformant to Event Stream Coding
    ///
    ///     ┌───────────┬───────────────┬──────────┬────────────┬─────────────────┐
    ///     │Header Name│  Header Name  │  Header  │Value String│                 │
    ///     │Byte Length│   (String)    │Value Type│ Byte Length│   Value String  │
    ///     ├───────────┼───────────────┼──────────┼────────────┼─────────────────┤
    ///     │  1 byte   │Variable Length│  1 byte  │   2 bytes  │ Variable Length │
    ///     │           │               │          │            │                 │
    struct Header: Codable {
        /// The byte-length of the header name.
        let nameByteLength: Int

        /// The name of the header indicating the header type.
        let name: String

        /// An enumeration indicating the header value.
        ///
        ///     The following shows the possible values for the header and what they indicate.
        ///     - 0 – .true
        ///     - 1 – .false
        ///     - 2 – .byte
        ///     - 3 – .short
        ///     - 4 – .integer
        ///     - 5 – .long
        ///     - 6 – .byteArray
        ///     - 7 – .string
        ///     - 8 – .timestamp
        ///     - 9 – .uuid
        ///
        /// - Note: All `Header().value`s use `String`
        let valueType: ValueType

        /// The byte-length of the header value string.
        let valueByteLength: Int16

        /// The value of the header. Valid values for this field depend on the type of header.
        let value: String
    }
}

extension EventStream.Header {
    /// Utility type used for encoding request conformant to Event Stream Encoding.
    ///
    ///  Each case's `rawValue` represents the byte marker for determining (decoding) / defining (encoding)
    ///  the type of the header's value.
    enum ValueType: UInt8, Codable {
        case `true` = 0
        case `false` = 1
        case byte = 2
        case short = 3
        case integer = 4
        case long = 5
        case byteArray = 6
        case string = 7
        case timestamp = 8
        case uuid = 9
    }
}



