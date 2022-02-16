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

class UploadFileTests: XCTestCase {

    func testUploadFileCreation() throws {
        let fs = FileSystem()
        let fileURL = fs.createTemporaryFileURL()
        let temporaryFileCreated = true
        let bytes = Bytes.megabytes(250)
        let file = UploadFile(fileURL: fileURL, temporaryFileCreated: temporaryFileCreated, size: UInt64(bytes.bytes))

        XCTAssertEqual(fileURL, file.fileURL)
        XCTAssertEqual(temporaryFileCreated, file.temporaryFileCreated)
        XCTAssertEqual(UInt64(bytes.bytes), file.size)
    }

}
