//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

class BytesTests: XCTestCase {

    func testBytes() throws {
        XCTAssertEqual(Bytes.terabytes(1).bytes, Bytes.gigabytes(1).bytes * 1_024)
        XCTAssertEqual(Bytes.gigabytes(1).bytes, Bytes.megabytes(1).bytes * 1_024)
        XCTAssertEqual(Bytes.megabytes(1).bytes, Bytes.kilobytes(1).bytes * 1_024)
        XCTAssertEqual(Bytes.kilobytes(1).bytes, Bytes.bytes(1).bytes * 1_024)
        XCTAssertEqual(Bytes.bytes(1).bytes, 1)
        XCTAssertEqual(Bytes.bytes(1).bits, 8)
    }

    func testMaximumBytesForMultipartUploadObjectSize() throws {
        let bytes = Bytes.terabytes(5)
        print("Bytes: \(bytes.bytes)")
        print("Int Max: \(Int.max)")
        XCTAssertTrue(bytes.bytes < Int.max)
    }
}
