//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import AWSClientRuntime

class DataExtensionTests: XCTestCase {
    func testBytesReturnsAnArrayOfBytes() {
        let expectedBytes: [UInt8] = [
            0x68,   // h
            0x65,   // e
            0x6C,   // l
            0x6C,   // l
            0x6F    // o
        ]
        let data = "hello".data(using: .utf8)!
        let bytes = data.bytes()
        XCTAssertEqual(bytes, expectedBytes)
    }

    func testChunkedReturnsEqualSizedChunks() {
        let data = Data(repeating: 0x01, count: 12)
        let chunks = data.chunked(size: 3)
        XCTAssertEqual(chunks.count, 4)
        chunks.forEach {
            XCTAssertEqual($0.count, 3)
        }
    }

    func testLastItemInChunkedIsLessThanSize() {
        let data = Data(repeating: 0x01, count: 15)
        let chunks = data.chunked(size: 2)
        XCTAssertEqual(chunks.count, 8)
        for i in (0...7) {
            if i == 7 {
                XCTAssertEqual(chunks[i].count, 1)
            } else {
                XCTAssertEqual(chunks[i].count, 2)
            }
        }
    }
}
