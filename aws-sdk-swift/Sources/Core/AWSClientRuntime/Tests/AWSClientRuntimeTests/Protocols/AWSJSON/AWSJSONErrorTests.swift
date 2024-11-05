//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyTestUtil
import SmithyHTTPAPI
import Smithy
@_spi(SmithyReadWrite) import class SmithyJSON.Reader
@_spi(SmithyReadWrite) import struct AWSClientRuntime.AWSJSONError
@_spi(SmithyReadWrite) import enum ClientRuntime.BaseErrorDecodeError
import XCTest

class AWSJSONErrorTests: HttpResponseTestBase {
    // These error codes are taken from the examples in
    // https://smithy.io/2.0/aws/protocols/aws-json-1_0-protocol.html#operation-error-serialization
    // (one extra case with leading & trailing whitespace is added)
    let errorCodes = [
        "FooError",
        "   FooError  ",
        "FooError:http://internal.amazon.com/coral/com.amazon.coral.validate/",
        "aws.protocoltests.restjson#FooError",
        "aws.protocoltests.restjson#FooError:http://internal.amazon.com/coral/com.amazon.coral.validate/"
    ]

    // MARK: - error code decoding & sanitization

    func test_errorInitThrowsIfNoCode() async throws {
        let httpResponse = try httpResponseWithNoErrorCode()
        let reader = try await Reader.from(data: httpResponse.body.readData() ?? Data())
        XCTAssertThrowsError(try AWSJSONError(httpResponse: httpResponse, responseReader: reader, noErrorWrapping: true)) { error in
            XCTAssertTrue((error as? BaseErrorDecodeError) == BaseErrorDecodeError.missingRequiredData)
        }
    }

    func test_sanitizeErrorCodeInHeader() async throws {
        for errorCode in errorCodes {
            let httpResponse = try httpResponseWithHeaderErrorCode(errorCode: errorCode)
            let reader = try await Reader.from(data: httpResponse.body.readData() ?? Data())
            let awsJSONError = try AWSJSONError(httpResponse: httpResponse, responseReader: reader, noErrorWrapping: true)
            XCTAssertEqual(awsJSONError.code, "FooError", "Error code '\(errorCode)' was not sanitized correctly, result was '\(awsJSONError.code)'")
        }
    }

    func test_sanitizeErrorCodeInCodeField() async throws {
        for errorCode in errorCodes {
            let httpResponse = try httpResponseWithCodeFieldErrorCode(errorCode: errorCode)
            let reader = try await Reader.from(data: httpResponse.body.readData() ?? Data())
            let awsJSONError = try AWSJSONError(httpResponse: httpResponse, responseReader: reader, noErrorWrapping: true)
            XCTAssertEqual(awsJSONError.code, "FooError", "Error code '\(errorCode)' was not sanitized correctly, result was '\(awsJSONError.code)'")
        }
    }

    func test_sanitizeErrorCodeInTypeField() async throws {
        for errorCode in errorCodes {
            let httpResponse = try httpResponseWithTypeFieldErrorCode(errorCode: errorCode)
            let reader = try await Reader.from(data: httpResponse.body.readData() ?? Data())
            let awsJSONError = try AWSJSONError(httpResponse: httpResponse, responseReader: reader, noErrorWrapping: true)
            XCTAssertEqual(awsJSONError.code, "FooError", "Error code '\(errorCode)' was not sanitized correctly, result was '\(awsJSONError.code)'")
        }
    }

    // MARK: - Private methods

    private func httpResponseWithNoErrorCode() throws -> HTTPResponse {
        guard let response = buildHttpResponse(
            code: 400,
            headers: [
                "Content-Type": "application/json",
            ],
            content: ByteStream.data(Data("{}".utf8))
        ) else {
            throw TestError("Something is wrong with the created http response")
        }
        return response
    }

    private func httpResponseWithHeaderErrorCode(errorCode: String) throws -> HTTPResponse {
        guard let response = buildHttpResponse(
            code: 400,
            headers: [
                "Content-Type": "application/json",
                "X-Amzn-Errortype": errorCode,
            ],
            content: ByteStream.data(Data("{}".utf8))
        ) else {
            throw TestError("Something is wrong with the created http response")
        }
        return response
    }

    private func httpResponseWithCodeFieldErrorCode(errorCode: String) throws -> HTTPResponse {
        guard let response = buildHttpResponse(
            code: 400,
            headers: [
                "Content-Type": "application/json",
            ],
            content: ByteStream.data(Data("{\"code\":\"\(errorCode)\"}".utf8))
        ) else {
            throw TestError("Something is wrong with the created http response")
        }
        return response
    }

    private func httpResponseWithTypeFieldErrorCode(errorCode: String) throws -> HTTPResponse {
        guard let response = buildHttpResponse(
            code: 400,
            headers: [
                "Content-Type": "application/json",
            ],
            content: ByteStream.data(Data("{\"__type\":\"\(errorCode)\"}".utf8))
        ) else {
            throw TestError("Something is wrong with the created http response")
        }
        return response
    }
}
