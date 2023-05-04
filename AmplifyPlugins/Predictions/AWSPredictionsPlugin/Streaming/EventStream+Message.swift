//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension EventStream {
    /// Represents the shape of a message conforming to Event Stream Coding pre encoding
    /// or post decoding.
    ///
    ///     ◀───────── Prelude ──────▶           ◀────────── Data ─────────▶
    ///     │                        │           │                         │             │
    ///     │                        │           │                         │             │
    ///     ├───────────┬────────────┼───────────┼─────────┬───────────────┼─────────────┤
    ///     │Total Byte │Headers Byte│           │         │               │             │
    ///     │  Length   │   Length   │Prelude CRC│ Headers │    Payload    │ Message CRC │
    ///     ├───────────┼────────────┼───────────┼─────────┼───────────────┼─────────────┤
    ///     │  4 bytes  │  4 bytes   │  4 bytes  │         │Variable Length│  4 bytes    │
    ///     │           │            │           │         │               │             │
    ///                                         ╱           ╲
    ///                                        ╱             ╲
    ///                                       ╱               ╲
    ///          ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ╱                 ╲ ─ ─ ─ ─ ─
    ///         ╱                                                          ╲
    ///        ╱                                                            ╲
    ///       ╱                                                              ╲
    ///      ╱                                                                ╲
    ///     ╱   Headers                                                        ╲
    ///     ┌───────────┬───────────────┬──────────┬────────────┬─────────────────┐
    ///     │Header Name│  Header Name  │  Header  │Value String│                 │
    ///     │Byte Length│   (String)    │Value Type│ Byte Length│   Value String  │
    ///     ├───────────┼───────────────┼──────────┼────────────┼─────────────────┤
    ///     │  1 byte   │Variable Length│  1 byte  │   2 bytes  │ Variable Length │
    ///     │           │               │          │            │                 │
    ///
    /// - Important: Despite Event Stream expecting Big Endian, this representation uses Little Endian
    /// to ease the use on Darwin platforms.
    struct Message {
        /// 32 bit signed Integer representing the total byte length of the message
        /// and occupies the first 4 bytes of the message
        let totalByteLength: Int32

        /// 32 bit signed Integer representing the byte length of the headers
        /// and occupies the bytes 5 - 8 of the message (one-indexed)
        let headersByteLength: Int32

        /// CRC of the prelude (total byte length and header byte length)
        let preludeCRC: Int32

        /// Headers included in the message
        let headers: [Header]

        /// The payload of the message
        let payload: Data

        /// CRC of the entire message occupying the last
        /// 4 bytes of the message
        let messageCRC: Int32
    }
}


