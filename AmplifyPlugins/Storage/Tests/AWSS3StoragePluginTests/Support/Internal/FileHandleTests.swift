//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class FileHandleTests: XCTestCase {
    
    /// Given: A FileHandle and a file
    /// When: `read(bytes:bytesReadLimit)` is invoked with `bytesReadLimit` being lower than `bytes`
    /// Then: Only `bytesReadLimit` bytes will be read at a time, but all `bytes` will be read and returned
    func testRead_withBytesHigherThanLimit_shouldSucceedByReadingMultipleTimes() throws {
        let sourceString = "012345678910" // 11 bytes
        let sourceData = Data(sourceString.utf8)
        let sourceFile = try createFile(from: sourceData)
        XCTAssertEqual(try StorageRequestUtils.getSize(sourceFile), UInt64(sourceString.count))
        
        let fileSystem = FileSystem()
        let bytesReadLimit = 2
        
        let fileHandle = try FileHandle(forReadingFrom: sourceFile)
        let firstPartData = try fileHandle.read(bytes: 5, bytesReadLimit: bytesReadLimit)
        let firstPartString = String(decoding: firstPartData, as: UTF8.self)
        XCTAssertEqual(firstPartString, "01234") // i.e. the first 5 bytes
        
        let secondPartData = try fileHandle.read(bytes: 5, bytesReadLimit: bytesReadLimit)
        let secondPartString = String(decoding: secondPartData, as: UTF8.self)
        XCTAssertEqual(secondPartString, "56789") // i.e. the second 5 bytes
        
        let thirdPartData = try fileHandle.read(bytes: 5, bytesReadLimit: bytesReadLimit)
        let thirdPartString = String(decoding: thirdPartData, as: UTF8.self)
        XCTAssertEqual(thirdPartString, "10") // i.e. the remaining bytes
        
        try FileManager.default.removeItem(at: sourceFile)
    }

    private func createFile(from data: Data) throws -> URL {
        let fileUrl = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("\(UUID().uuidString).tmp")
        try data.write(to: fileUrl, options: .atomic)
        return fileUrl
    }
}
