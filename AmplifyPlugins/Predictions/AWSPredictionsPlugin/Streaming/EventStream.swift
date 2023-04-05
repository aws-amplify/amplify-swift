//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/**
 Event Stream Encoding


         ◀───────── Prelude ──────▶           ◀────────── Data ─────────▶
         │                        │           │                         │             │
         │                        │           │                         │             │
         ├───────────┬────────────┼───────────┼─────────┬───────────────┼─────────────┤
         │Total Byte │Headers Byte│           │         │               │             │
         │  Length   │   Length   │Prelude CRC│ Headers │    Payload    │ Message CRC │
         ├───────────┼────────────┼───────────┼─────────┼───────────────┼─────────────┤
         │  4 bytes  │  4 bytes   │  4 bytes  │         │Variable Length│  4 bytes    │
         │           │            │           │         │               │             │
                                             ╱           ╲
                                            ╱             ╲
                                           ╱               ╲
              ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ╱                 ╲ ─ ─ ─ ─ ─
             ╱                                                          ╲
            ╱                                                            ╲
           ╱                                                              ╲
          ╱                                                                ╲
         ╱   Headers                                                        ╲
        ┌───────────┬───────────────┬──────────┬────────────┬─────────────────┐
        │Header Name│  Header Name  │  Header  │Value String│                 │
        │Byte Length│   (String)    │Value Type│ Byte Length│   Value String  │
        ├───────────┼───────────────┼──────────┼────────────┼─────────────────┤
        │  1 byte   │Variable Length│  1 byte  │   2 bytes  │ Variable Length │
        │           │               │          │            │                 │

 - **Prelude:** Always a fixed size of 8 bytes, two fields of 4 bytes each.**

    - First 4 bytes: The total byte-length. This is the big-endian integer byte-length of the entire message, including the 4-byte length field itself.
    - Second 4 bytes: The headers byte-length. This is the big-endian integer byte-length of the headers portion of the message, excluding the headers length field itself.

 - **Prelude CRC:** The 4-byte CRC checksum for the prelude portion of the message, excluding the CRC itself. The prelude has a separate CRC from the message CRC to ensure that Amazon Transcribe Medical can detect corrupted byte-length information immediately without causing errors such as buffer overruns.**

 - **Headers:** Metadata annotating the message, such as the message type, content type, and so on. Messages have multiple headers. Headers are key-value pairs where the key is a UTF-8 string. Headers can appear in any order in the headers portion of the message and any given header can appear only once. For the required header types, see the following sections.

 - **Payload:** The audio content to be transcribed.

 - **Message CRC:** The 4-byte CRC checksum from the start of the message to the start of the checksum. That is, everything in the message except the CRC itself.

 Each header contains the following components. There are multiple headers per frame.

 - **Header name byte-length:** The byte-length of the header name.

 - **Header name:** The name of the header indicating the header type. For valid values, see the following frame descriptions.

 - **Header value type:** An enumeration indicating the header value.

     The following shows the possible values for the header and what they indicate.
     - 0 – TRUE
     - 1 – FALSE
     - 2 – BYTE
     - 3 – SHORT
     - 4 – INTEGER
     - 5 – LONG
     - 6 – BYTE ARRAY
     - 7 – STRING
     - 8 – TIMESTAMP
     - 9 – UUID

 - **Value string byte length:** The byte-length of the header value string.

 - **Header value:** The value of the header string. Valid values for this field depend on the type of header. For valid values, see the following frame descriptions.
 */
enum EventStream {}
