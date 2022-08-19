//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

class StorageUploadPartTests: XCTestCase {

    func testUploadPartCreation() throws {
        // Creates an array of upload parts with 21 parts
        // where the last part is 512 bytes.
        let lastPartSize = 512
        let partSize: StorageUploadPartSize = .default
        let fileSize: UInt64 = UInt64(partSize.size * 20 + lastPartSize)
        let parts = try StorageUploadParts(fileSize: fileSize, partSize: partSize)
        XCTAssertEqual(parts.count, 21)
        XCTAssertEqual(parts.pending.count, parts.count)
        XCTAssertEqual(parts.inProgress.count, 0)
        XCTAssertEqual(parts.failed.count, 0)
        XCTAssertEqual(parts.completed.count, 0)
        XCTAssertEqual(parts.first?.bytes, partSize.size)
        XCTAssertEqual(parts.last?.bytes, lastPartSize)
    }

    func testStorageUploadPartsComputedProperties() throws {
        let parts: StorageUploadParts = [
            .inProgress(bytes: 100, bytesTransferred: 50, taskIdentifier: 1),
            .inProgress(bytes: 100, bytesTransferred: 50, taskIdentifier: 1),
            .inProgress(bytes: 100, bytesTransferred: 50, taskIdentifier: 1),
            .inProgress(bytes: 100, bytesTransferred: 50, taskIdentifier: 1)
        ]

        XCTAssertFalse(parts.isDone)
        XCTAssertFalse(parts.isFailed)
        XCTAssertFalse(parts.hasPending)
        XCTAssertEqual(parts.pending.count, 0)
        XCTAssertEqual(parts.inProgress.count, parts.count)
        XCTAssertEqual(parts.failed.count, 0)
        XCTAssertEqual(parts.completed.count, 0)
        XCTAssertEqual(parts.totalBytes, 100 * parts.count)
        XCTAssertEqual(parts.bytesTransferred, 50 * parts.count)
        XCTAssertEqual(parts.percentTransferred, 0.5)
    }

}
