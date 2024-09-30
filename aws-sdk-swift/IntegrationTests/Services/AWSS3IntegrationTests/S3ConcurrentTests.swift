//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Smithy
import SmithyStreams
import XCTest
import AWSS3
import AWSIntegrationTestUtils

class S3ConcurrentTests: S3XCTestCase {
    public var fileData: Data!
    let MEGABYTE: Double = 1_000_000

    // Payload below 1,048,576 bytes; sends as simple data payload
    func test_100x_1MB_getObject() async throws {
        fileData = try generateDummyTextData(numMegabytes: MEGABYTE)
        try await repeatConcurrentlyWithArgs(count: 100, test: getObject, args: fileData!)
    }

    // Payload over 1,048,576 bytes; uses aws chunked encoding & flexible checksum
    func test_100x_1_5MB_getObject() async throws {
        fileData = try generateDummyTextData(numMegabytes: MEGABYTE * 1.5)
        try await repeatConcurrentlyWithArgs(count: 100, test: getObject, args: fileData!)
    }

    /* Helper functions */

    // Generates text data in increments of 10 bytes
    func generateDummyTextData(numMegabytes: Double) throws -> Data {
        let segmentData = Data("1234567890".utf8)
        var wholeData = Data()
        for _ in 0..<(Int(numMegabytes)/10) {
            wholeData.append(segmentData)
        }
        return wholeData
    }

    // Puts data to S3, gets the uploaded file, then asserts retrieved data equals original data
    func getObject(args: Any...) async throws {
        guard let data = args[0] as? Data else {
            throw ClientError.dataNotFound("Failed to retrieve dummy data.")
        }
        let file = ByteStream.data(data)
        let objectKey = UUID().uuidString.split(separator: "-").first!.lowercased()
        let putObjectInput = PutObjectInput(body: file, bucket: bucketName, key: objectKey)
        _ = try await client.putObject(input: putObjectInput)
        let retrievedData = try await client.getObject(input: GetObjectInput(
            bucket: bucketName, key: objectKey
        )).body?.readData()
        XCTAssertEqual(data, retrievedData)
    }
}
