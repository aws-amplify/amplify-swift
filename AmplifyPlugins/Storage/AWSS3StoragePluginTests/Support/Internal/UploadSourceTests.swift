//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable identifier_name

import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

class UploadSourceTests: XCTestCase {

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
