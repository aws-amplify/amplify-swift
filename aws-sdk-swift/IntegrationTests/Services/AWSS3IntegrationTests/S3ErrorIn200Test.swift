//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import Foundation
import XCTest
import AWSS3
import AWSClientRuntime
@_spi(UnknownAWSHTTPServiceError) import struct AWSClientRuntime.UnknownAWSHTTPServiceError
import AwsCommonRuntimeKit
import ClientRuntime

public class MockHttpClientEngine: HTTPClient {
    private let errorResponsePayload: String

    // Public initializer
    public init(response: String) {
        self.errorResponsePayload = response
    }

    func successHttpResponse(request: SmithyHTTPAPI.HTTPRequest) -> HTTPResponse {
        request.withHeader(name: "Date", value: "Wed, 21 Oct 2015 07:28:00 GMT")
        return HTTPResponse(
            headers: request.headers,
            body: ByteStream.data(self.errorResponsePayload.data(using: .utf8)),
            statusCode: .ok
        )
    }

    public func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> HTTPResponse {
        return successHttpResponse(request: request)
    }
}

class S3ErrorIn200Test: XCTestCase {

    let errorInternalErrorResponsePayload = """
        <Error>
            <Code>InternalError</Code>
            <Message>We encountered an internal error. Please try again.</Message>
            <RequestId>656c76696e6727732072657175657374</RequestId>
            <HostId>Uuag1LuByRx9e6j5Onimru9pO4ZVKnJ2Qz7/C1NPcfTWAtRPfTaOFg==</HostId>
        </Error>
    """

    let errorSlowDownResponsePayload = """
        <Error>
            <Code>SlowDown</Code>
            <Message>Please reduce your request rate.</Message>
            <RequestId>K2H6N7ZGQT6WHCEG</RequestId>
            <HostId>WWoZlnK4pTjKCYn6eNV7GgOurabfqLkjbSyqTvDMGBaI9uwzyNhSaDhOCPs8paFGye7S6b/AB3A=</HostId>
        </Error>
    """

    let shouldNotApplyResponsePayload = """
        <DeleteResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <Deleted>
                <Key>sample1.txt</Key>
            </Deleted>
            <Error>
                <Key>sample2.txt</Key>
                <Code>AccessDenied</Code>
                <Message>Access Denied</Message>
            </Error>
        </DeleteResult>
    """

    override class func setUp() {
        AwsCommonRuntimeKit.CommonRuntimeKit.initialize()
    }

    /// S3Client throws expected InternalError error in response (200) with <Error> tag
    func test_foundInternalErrorExpectedError() async throws {
        let config = try await S3Client.S3ClientConfiguration(region: "us-west-2")
        config.httpClientEngine = MockHttpClientEngine(response: errorInternalErrorResponsePayload)
        let client = S3Client(config: config)

        do {
            // any method on S3Client where the output shape doesnt have a blob stream
            _ = try await client.listBuckets(input: .init())
            XCTFail("Expected an error to be thrown, but it was not.")
        } catch let error as UnknownAWSHTTPServiceError {
            // check for the error we added in our mock client
            XCTAssertEqual("InternalError", error.typeName)
            XCTAssertEqual("We encountered an internal error. Please try again.", error.message)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// S3Client throws expected SlowDown error in response (200) with <Error> tag
    func test_foundSlowDownExpectedError() async throws {
        let config = try await S3Client.S3ClientConfiguration(region: "us-west-2")
        config.httpClientEngine = MockHttpClientEngine(response: errorSlowDownResponsePayload)
        let client = S3Client(config: config)

        do {
            // any method on S3Client where the output shape doesnt have a blob stream
            _ = try await client.listBuckets(input: .init())
            XCTFail("Expected an error to be thrown, but it was not.")
        } catch let error as UnknownAWSHTTPServiceError {
            // check for the error we added in our mock client
            XCTAssertEqual("SlowDown", error.typeName)
            XCTAssertEqual("Please reduce your request rate.", error.message)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    /// S3Client does not throw error when <Error> is not at the root
    func test_noErrorExpected() async throws {
        let config = try await S3Client.S3ClientConfiguration(region: "us-west-2")
        config.httpClientEngine = MockHttpClientEngine(response: shouldNotApplyResponsePayload)
        let client = S3Client(config: config)

        do {
            // any method on S3Client where the output shape doesnt have a stream
            let result = try await client.deleteObjects(input: .init(delete: .init(objects: [.init(key: "test")])))

            // Check results
            XCTAssertEqual(result.deleted?.count, 1)
            XCTAssertEqual(result.errors?.count, 1)

            let actualDeleted = result.deleted?.first
            XCTAssertEqual(actualDeleted?.key, "sample1.txt")

            let actualError = result.errors?.first
            XCTAssertEqual(actualError?.code, "AccessDenied")
            XCTAssertEqual(actualError?.key, "sample2.txt")
        } catch let error {
            XCTFail("Expected success, but received \(error).")
        }
    }
}
