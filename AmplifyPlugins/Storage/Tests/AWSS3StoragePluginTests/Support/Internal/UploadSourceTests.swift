//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable identifier_name

import XCTest

@testable import Amplify
@testable import AWSS3StoragePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class UploadSourceTests: XCTestCase, @unchecked Sendable {

    func testDataSource() throws {
        let fs = FileSystem()
        let bytes = Bytes.megabytes(100)
        let data = fs.randomData(bytes: bytes)
        let source = UploadSource.data(data)
        let file = try source.getFile()
        defer {
            fs.removeFileIfExists(fileURL: file.fileURL)
        }
        XCTAssertTrue(fs.fileExists(atURL: file.fileURL))
    }

    func testLocalSource() throws {
        let fs = FileSystem()
        let bytes = Bytes.megabytes(100)
        let data = fs.randomData(bytes: bytes)
        let fileURL = try fs.createTemporaryFile(data: data)
        let source = UploadSource.local(fileURL)
        let file = try source.getFile()
        defer {
            fs.removeFileIfExists(fileURL: file.fileURL)
        }
        XCTAssertTrue(fs.fileExists(atURL: file.fileURL))
    }

}
