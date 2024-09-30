//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import XCTest
import AWSS3
import SmithyHTTPAPI
@testable import ClientRuntime
import class SmithyStreams.BufferedStream
import class SmithyChecksums.ValidatingBufferedStream

final class S3FlexibleChecksumsTests: S3XCTestCase {
    var originalData: Data!

    override func setUp() {
        super.setUp()
        // Fill one MB with random data.  Data is refreshed for each flexible checksums tests below.
        originalData = Data((0..<(1024 * 1024)).map { _ in UInt8.random(in: UInt8.min...UInt8.max) })
    }

    // MARK: - Data uploads

    func test_putGetObject_data_crc32() async throws {
        try await _testPutGetObject(withChecksumAlgorithm: .crc32, objectNameSuffix: "crc32-data", upload: .data(originalData))
    }

    func test_putGetObject_data_crc32c() async throws {
        try await _testPutGetObject(withChecksumAlgorithm: .crc32c, objectNameSuffix: "crc32c-data", upload: .data(originalData))
    }

    func test_putGetObject_data_sha1() async throws {
        try await _testPutGetObject(withChecksumAlgorithm: .sha1, objectNameSuffix: "sha1-data", upload: .data(originalData))
    }

    func test_putGetObject_data_sha256() async throws {
        try await _testPutGetObject(withChecksumAlgorithm: .sha256, objectNameSuffix: "sha256-data", upload: .data(originalData))
    }

    // MARK: - Streaming uploads

    func test_putGetObject_streaming_crc32() async throws {
        let bufferedStream = BufferedStream(data: originalData, isClosed: true)
        try await _testPutGetObject(withChecksumAlgorithm: .crc32, objectNameSuffix: "crc32", upload: .stream(bufferedStream))
    }

    func test_putGetObject_streaming_crc32c() async throws {
        let bufferedStream = BufferedStream(data: originalData, isClosed: true)
        try await _testPutGetObject(withChecksumAlgorithm: .crc32c, objectNameSuffix: "crc32c", upload: .stream(bufferedStream))
    }

    func test_putGetObject_streaming_sha1() async throws {
        let bufferedStream = BufferedStream(data: originalData, isClosed: true)
        try await _testPutGetObject(withChecksumAlgorithm: .sha1, objectNameSuffix: "sha1", upload: .stream(bufferedStream))
    }

    func test_putGetObject_streaming_sha256() async throws {
        let bufferedStream = BufferedStream(data: originalData, isClosed: true)
        try await _testPutGetObject(withChecksumAlgorithm: .sha256, objectNameSuffix: "sha256", upload: .stream(bufferedStream))
    }

    // Streaming without checksum (chunked encoding)
    func test_putGetObject_streaming_chunked() async throws {
        let bufferedStream = BufferedStream(data: originalData, isClosed: true)
        let objectName = "flexible-checksums-s3-test-chunked"

        let putObjectInput = PutObjectInput(
            body: .stream(bufferedStream),
            bucket: bucketName,
            key: objectName
        )

        _ = try await client.putObject(input: putObjectInput)

        let getObjectInput = GetObjectInput(bucket: bucketName, key: objectName)
        let getObjectOutput = try await client.getObject(input: getObjectInput)
        let body = try XCTUnwrap(getObjectOutput.body)
        let data = try await body.readData()
        XCTAssertEqual(data, originalData)
    }

    // Streaming unsigned payload without checksum (chunked encoding)
    class DisablePayloadSigning<InputType, OutputType>: Interceptor {
        typealias RequestType = HTTPRequest
        typealias ResponseType = HTTPResponse

        func modifyBeforeRetryLoop(context: some MutableRequest<InputType, RequestType>) async throws {
            context.getAttributes().set(key: SmithyHTTPAPIKeys.hasUnsignedPayloadTrait, value: true)
        }
        func modifyBeforeTransmit(context: some MutableRequest<InputType, RequestType>) async throws {
            context.getRequest().withHeader(name: "x-amz-content-sha256", value: "STREAMING-UNSIGNED-PAYLOAD-TRAILER")
        }
    }

    class DisablePayloadSigningProvider: HttpInterceptorProvider {
        func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
            return DisablePayloadSigning()
        }
    }

    func test_putGetObject_streamining_unsigned_chunked() async throws {
        let config = try await S3Client.S3ClientConfiguration(region: region)
        config.addInterceptorProvider(DisablePayloadSigningProvider())
        let customizedClient = S3Client(config: config)

        let bufferedStream = BufferedStream(data: originalData, isClosed: true)
        let objectName = "flexible-checksums-s3-test-unsigned-chunked"

        let putObjectInput = PutObjectInput(
            body: .stream(bufferedStream),
            bucket: bucketName,
            key: objectName
        )

        _ = try await customizedClient.putObject(input: putObjectInput)

        let getObjectInput = GetObjectInput(bucket: bucketName, key: objectName)
        let getObjectOutput = try await client.getObject(input: getObjectInput)
        let body = try XCTUnwrap(getObjectOutput.body)
        let data = try await body.readData()
        XCTAssertEqual(data, originalData)
    }


    // MARK: - Private methods

    private func _testPutGetObject(
        withChecksumAlgorithm algorithm: S3ClientTypes.ChecksumAlgorithm,
        objectNameSuffix: String, upload: ByteStream, file: StaticString = #filePath, line: UInt = #line
    ) async throws {
        let objectName = "flexible-checksums-s3-test-\(objectNameSuffix)"

        let input = PutObjectInput(
            body: upload,
            bucket: bucketName,
            checksumAlgorithm: algorithm,
            key: objectName
        )

        let output = try await client.putObject(input: input)

        // Verify the checksum response based on the algorithm used.
        let checksumResponse = try XCTUnwrap(getChecksumResponse(from: output, with: algorithm), file: file, line: line)
        XCTAssertNotNil(checksumResponse, file: file, line: line)

        let getInput = GetObjectInput(bucket: bucketName, checksumMode: S3ClientTypes.ChecksumMode.enabled, key: objectName)
        let getOutput = try await client.getObject(input: getInput) // will error for normal payloads if checksum mismatch
        XCTAssertNotNil(getOutput.body, file: file, line: line) // Ensure there's a body in the response.

        // Additional step for stream: Validate stream and read data.
        if case .stream = upload {
            let streamingBody = try XCTUnwrap(getOutput.body, file: file, line: line)
            if case .stream(let stream) = streamingBody {
                XCTAssert(stream is ValidatingBufferedStream, "Expected ValidatingBufferedStream for streaming upload", file: file, line: line)
                let data = try await streamingBody.readData() // will error if checksum mismatch
                XCTAssertEqual(data, originalData, file: file, line: line)
            } else {
                XCTFail("Did not receive a stream when expected for checksum validation!", file: file, line: line)
            }
        }
    }

    private func getChecksumResponse(from response: PutObjectOutput, with algorithm: S3ClientTypes.ChecksumAlgorithm) throws -> String? {
        switch algorithm {
        case .crc32:
            return response.checksumCRC32
        case .crc32c:
            return response.checksumCRC32C
        case .sha1:
            return response.checksumSHA1
        case .sha256:
            return response.checksumSHA256
        default:
            XCTFail("Unsupported checksum algorithm")
            return nil
        }
    }
}
