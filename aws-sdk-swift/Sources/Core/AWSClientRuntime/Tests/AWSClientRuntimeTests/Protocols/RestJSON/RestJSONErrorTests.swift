/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Smithy
import SmithyHTTPAPI
@_spi(SmithyReadWrite) import SmithyReadWrite
@_spi(SmithyReadWrite) import SmithyJSON
import ClientRuntime
import SmithyTestUtil
import XCTest
@_spi(SmithyReadWrite) @testable import AWSClientRuntime
@_spi(UnknownAWSHTTPServiceError) import struct AWSClientRuntime.UnknownAWSHTTPServiceError

class RestJSONErrorTests: HttpResponseTestBase {
    let host = "myapi.host.com"

    func testRestJsonComplexError() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 400,
            headers: [
                "Content-Type": "application/json",
                "X-Header": "Header",
                "X-Amzn-Errortype": "ComplexError"
            ],
            content: ByteStream.data("""
            {\"TopLevel\": \"Top level\"}
            """.data(using: .utf8))
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
        }

        let greetingWithErrorsError = try await GreetingWithErrorsError.httpError(from:)(httpResponse)

        if let actual = greetingWithErrorsError as? ComplexError {
            let expected = ComplexError(
                header: "Header",
                topLevel: "Top level"
            )
            XCTAssertEqual(actual.httpResponse.statusCode, HTTPStatusCode(rawValue: 400))
            XCTAssertEqual(actual.header, expected.header)
            XCTAssertEqual(actual.topLevel, expected.topLevel)
        } else {
            XCTFail("The deserialized error type does not match expected type")
        }
    }

    func testSanitizeErrorName() {
        let errorNames = [
            "   FooError  ",
            "FooError:http://my.fake.com/",
            "my.protocoltests.restjson#FooError",
            "my.protocoltests.restjson#FooError:http://my.fake.com"
        ]

        for errorName in errorNames {
            XCTAssertEqual(sanitizeErrorType(errorName), "FooError")
        }
    }
}

public struct ComplexError: AWSServiceError, HTTPError, Error {
    public var typeName: String?
    public var httpResponse = HTTPResponse()
    public var message: String?
    public var requestID: String?
    public var header: String?
    public var topLevel: String?

    public init (
        header: String? = nil,
        topLevel: String? = nil
    ) {
        self.header = header
        self.topLevel = topLevel
    }
}

struct ComplexErrorBody {
    public let topLevel: String?
}

extension ComplexError {

    static func makeError(baseError: AWSClientRuntime.RestJSONError) throws -> ComplexError {
        let reader = baseError.errorBodyReader
        var value = ComplexError()
        if let Header = baseError.httpResponse.headers.value(for: "X-Header") {
            value.header = Header
        } else {
            value.header = nil
        }
        value.topLevel = try reader["TopLevel"].readIfPresent()
        value.httpResponse = baseError.httpResponse
        value.message = baseError.message
        value.requestID = baseError.requestID
        return value
    }
}

public enum GreetingWithErrorsError {
    
    static func httpError(from httpResponse: HTTPResponse) async throws -> Swift.Error {
        let data = try await httpResponse.data()
        let responseReader = try SmithyJSON.Reader.from(data: data)
        let baseError = try AWSClientRuntime.RestJSONError(httpResponse: httpResponse, responseReader: responseReader, noErrorWrapping: false)
        if let error = baseError.customError() { return error }
        switch baseError.code {
        case "ComplexError": return try ComplexError.makeError(baseError: baseError)
        default: return try AWSClientRuntime.UnknownAWSHTTPServiceError.makeError(baseError: baseError)
        }
    }
}
