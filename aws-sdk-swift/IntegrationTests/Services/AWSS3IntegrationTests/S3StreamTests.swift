//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import XCTest
import AWSS3
@testable import ClientRuntime
import class SmithyStreams.FileStream

final class S3StreamTests: S3XCTestCase {
    let objectName = "hello-world"
    let expected = "Hello, world!"

    func test_getObject() async throws {
        try await putObject(body: expected, key: objectName)
        let input = GetObjectInput(bucket: bucketName, key: objectName)
        let output = try await client.getObject(input: input)
        let body = try XCTUnwrap(output.body)
        switch body {
        case .data(let dataOrNil):
            let data = try XCTUnwrap(dataOrNil)
            let actual = String(data: data, encoding: .utf8)
            XCTAssertEqual(expected, actual)
        case .stream(let stream):
            let actual = String(data: try await stream.readToEndAsync() ?? Data(), encoding: .utf8)
            XCTAssertEqual(expected, actual)
        case .noStream:
            XCTFail("Expected stream")
        }
    }

    func test_putObject_givenDataBody() async throws {
        let input = PutObjectInput(body: .data(expected.data(using: .utf8)), bucket: bucketName, key: objectName)
        let output = try await client.putObject(input: input)
        XCTAssertNotNil(output)

        let actual = try await getObject(key: objectName)
        XCTAssertEqual(expected, actual)
    }
    
    func test_putObject_givenStreamBody() async throws {
        let audioURL = Bundle.module.url(forResource: objectName, withExtension: nil)!
        let fileHandle = FileHandle(forReadingAtPath: audioURL.relativePath)!
        let fileByteStream = ByteStream.stream(FileStream(fileHandle: fileHandle))
        let input = PutObjectInput(body: fileByteStream, bucket: bucketName, key: objectName)
        let output = try await client.putObject(input: input)
        XCTAssertNotNil(output)

        let actual = try await getObject(key: objectName)
        XCTAssertEqual(expected, actual)
    }
}
