//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSS3StoragePlugin

class AWSS3StorageGetRequestTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMandatoryFields() {
        // Arrange
        let requestBuilder = AWSS3StorageGetRequest.Builder(bucket: "bucket", key: "key", accessLevel: .Public)

        // Act
        let request = requestBuilder.build()

        // Assert
        XCTAssertNotNil(request)
        XCTAssertEqual(request.key, "key")
        XCTAssertEqual(request.bucket, "bucket")
        XCTAssertNil(request.fileURL)

    }

    func testOptionalFields() {
        // Arrange
        let url = URL(fileURLWithPath: "path")
        let requestBuilder = AWSS3StorageGetRequest.Builder(bucket: "bucket", key: "key", accessLevel: .Public)
            .accessLevel(.Private)
            .fileURL(url)
        let expectedKey = "private/key"

        // Act
        let request = requestBuilder.build()

        // Assert
        XCTAssertNotNil(request)
        XCTAssertEqual(request.key, expectedKey)
        XCTAssertEqual(request.bucket, "bucket")
        XCTAssertEqual(request.fileURL, url)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
