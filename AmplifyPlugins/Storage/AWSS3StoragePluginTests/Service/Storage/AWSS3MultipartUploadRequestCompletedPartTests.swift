//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

class AWSS3MultipartUploadRequestCompletedPartTests: XCTestCase {

    func testSessionWithCompletedParts() throws {
        let completedParts: StorageUploadParts = [
            .completed(bytes: Bytes.megabytes(5).bytes, eTag: "eTag-1"),
            .completed(bytes: Bytes.megabytes(5).bytes, eTag: "eTag-2"),
            .completed(bytes: Bytes.megabytes(5).bytes, eTag: "eTag-3"),
            .completed(bytes: Bytes.megabytes(5).bytes, eTag: "eTag-4"),
            .completed(bytes: Bytes.megabytes(5).bytes, eTag: "eTag-5"),
        ]

        let multipartUploadRequestCompletedParts = AWSS3MultipartUploadRequestCompletedParts(completedParts: completedParts)

        XCTAssertEqual(completedParts.count, 5)
        XCTAssertEqual(multipartUploadRequestCompletedParts.count, 5)

        XCTAssertEqual(completedParts[0].eTag, "eTag-1")
        XCTAssertEqual(completedParts[1].eTag, "eTag-2")
        XCTAssertEqual(completedParts[2].eTag, "eTag-3")
        XCTAssertEqual(completedParts[3].eTag, "eTag-4")
        XCTAssertEqual(completedParts[4].eTag, "eTag-5")

        XCTAssertEqual(multipartUploadRequestCompletedParts[0].partNumber, 1)
        XCTAssertEqual(multipartUploadRequestCompletedParts[1].partNumber, 2)
        XCTAssertEqual(multipartUploadRequestCompletedParts[2].partNumber, 3)
        XCTAssertEqual(multipartUploadRequestCompletedParts[3].partNumber, 4)
        XCTAssertEqual(multipartUploadRequestCompletedParts[4].partNumber, 5)

        XCTAssertEqual(multipartUploadRequestCompletedParts[0].eTag, "eTag-1")
        XCTAssertEqual(multipartUploadRequestCompletedParts[1].eTag, "eTag-2")
        XCTAssertEqual(multipartUploadRequestCompletedParts[2].eTag, "eTag-3")
        XCTAssertEqual(multipartUploadRequestCompletedParts[3].eTag, "eTag-4")
        XCTAssertEqual(multipartUploadRequestCompletedParts[4].eTag, "eTag-5")
    }
    
}
