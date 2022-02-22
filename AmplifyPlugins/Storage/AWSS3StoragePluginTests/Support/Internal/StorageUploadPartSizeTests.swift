//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

class StorageUploadPartSizeTests: XCTestCase {

    func testUploadPartSizes() throws {
        XCTAssertGreaterThanOrEqual(StorageUploadPartSize.default.size, minimumPartSize)
        XCTAssertLessThanOrEqual(StorageUploadPartSize.default.size, maximumPartSize)

        XCTAssertThrowsError(try StorageUploadPartSize(size: minimumPartSize - 5))
        XCTAssertThrowsError(try StorageUploadPartSize(size: maximumPartSize + 5))

        XCTAssertNoThrow(try StorageUploadPartSize(size: minimumPartSize + 5))
        XCTAssertNoThrow(try StorageUploadPartSize(size: maximumPartSize - 5))

        XCTAssertNoThrow(try StorageUploadPartSize(size: minimumPartSize))
        XCTAssertNoThrow(try StorageUploadPartSize(size: maximumPartSize))
    }

    func testUploadPartSizeForSmallFile() throws {
        do {
            let fileSize = UInt64(minimumPartSize / 2)
            let partSize = try StorageUploadPartSize(fileSize: fileSize)
            XCTAssertEqual(partSize.size, minimumPartSize)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testUploadPartSizeForEmptyFile() throws {
        let fileSize = UInt64(0)
        XCTAssertThrowsError(try StorageUploadPartSize(fileSize: fileSize))
    }

    func testUploadPartSizeForTooLargeFile() throws {
        let fileSize = UInt64(maximumObjectSize + 512)
        XCTAssertThrowsError(try StorageUploadPartSize(fileSize: fileSize))
    }

    func testUploadPartSizeForLargeValidFile() throws {
        // use a file size which requires increasing from minimum part size
        let fileSize = UInt64(minimumPartSize * maximumPartCount * 10)
        let partSize = assertNoThrow(try StorageUploadPartSize(fileSize: fileSize))
        XCTAssertNotNil(partSize)
        if let partSize = partSize,
           let parts = try? StorageUploadParts(fileSize: fileSize, partSize: partSize) {
            print("Part Size: \(partSize.size)")
            print("Parts Count: \(parts.count)")
            XCTAssertGreaterThan(partSize.size, minimumPartSize)
            XCTAssertLessThan(partSize.size, maximumPartSize)
        }
    }

    func testUploadPartSizeForSuperCrazyBigFile() throws {
        // use the maximum object size / max part count
        let fileSize = UInt64(maximumObjectSize / maximumPartCount)
        let partSize = assertNoThrow(try StorageUploadPartSize(fileSize: fileSize))
        XCTAssertNotNil(partSize)
        if let partSize = partSize,
           let parts = try? StorageUploadParts(fileSize: fileSize, partSize: partSize) {
            print("Part Size: \(partSize.size)")
            print("Parts Count: \(parts.count)")
            print("Max Part Size: \(maximumPartSize)")
            print("Max Part Count: \(maximumPartCount)")
            XCTAssertLessThan(partSize.size, maximumPartSize)
            XCTAssertLessThanOrEqual(parts.count, maximumPartCount)
        }
    }

    func testUploadPartSizeFiftyGigabyteFile() throws {
        // use the maximum object size / max part count
        let fileSize = UInt64(Bytes.gigabytes(50).bytes)
        print("      File Size: \(fileSize)")
        print("Max Object Size: \(maximumObjectSize)")
        let partSize = assertNoThrow(try StorageUploadPartSize(fileSize: fileSize))
        XCTAssertNotNil(partSize)
        if let partSize = partSize,
           let parts = try? StorageUploadParts(fileSize: fileSize, partSize: partSize) {
            print("     Part Size: \(partSize.size)")
            print("   Parts Count: \(parts.count)")
            print(" Min Part Size: \(minimumPartSize)")
            print("Min Part Count: \(minimumPartCount)")
            print(" Max Part Size: \(maximumPartSize)")
            print("Max Part Count: \(maximumPartCount)")
            XCTAssertGreaterThan(partSize.size, minimumPartSize)
            XCTAssertLessThan(partSize.size, maximumPartSize)
            XCTAssertLessThanOrEqual(parts.count, maximumPartCount)
        }
    }

    func assertNoThrow<T>(
        _ expression: @autoclosure () throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line) -> T? {
        var result: T?
        XCTAssertNoThrow(
            try { result = try expression() }(), message(), file: file, line: line)
        return result
    }

}
