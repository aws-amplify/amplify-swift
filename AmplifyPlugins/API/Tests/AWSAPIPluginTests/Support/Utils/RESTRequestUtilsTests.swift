//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSAPIPlugin

class RESTRequestUtilsTests: XCTestCase {
    private func assertQueryParameters(
        testCase: Int,
        withURL url: URL,
        expected: [String: String]?
    ) throws {
        var queryParams: [String: String] = [:]
        url.query?.split(separator: "&").forEach {
            let components = $0.split(separator: "=")
            if let name = components.first, let value = components.last {
                queryParams[String(name)] = String(value)
            }
        }

        guard let expected = expected else {
            return XCTAssertTrue(
                queryParams.isEmpty,
                "Test \(testCase): Unexpected query items found \(queryParams)"
            )
        }
        XCTAssertEqual(queryParams, expected, "Test \(testCase): query params mismatch")
    }

    func testConstructURL() throws {
        let baseURL = URL(string: "https://aws.amazon.com")!
        let path = "/projects"
        let base = ConstructURLTestCase(baseURL: baseURL, path: path)
        let testCases: [ConstructURLTestCase] = [
            base.withInput(.unencodedEmail).expecting(.unencodedEmail),
            base.withInput(.encodedEmail).expecting(.unencodedEmail),
            base.withInput(.unencodedDate).expecting(.unencodedDate),
            base.withInput(.encodedDate).expecting(.unencodedDate),
            base.withInput(.nilCase).expecting(.nilCase)
        ]

        for (index, test) in testCases.enumerated() {
            let resultURL = try RESTOperationRequestUtils.constructURL(
                for: test.baseURL,
                withPath: test.path,
                withParams: test.inputParams
            )

            try assertQueryParameters(
                testCase: index,
                withURL: resultURL,
                expected: test.expectedOutputParams
            )
        }
    }

    func testConstructURLRequest() throws {
        let baseURL = URL(string: "https://aws.amazon.com")!
        let url = try RESTOperationRequestUtils.constructURL(
            for: baseURL,
            withPath: "/projects",
            withParams: nil
        )

        let urlRequest = RESTOperationRequestUtils.constructURLRequest(
            with: url,
            operationType: .get,
            headers: nil,
            requestPayload: nil
        )

        XCTAssertEqual(urlRequest.httpMethod, RESTOperationType.get.rawValue)

        // a REST operation request should always have at least a "content-type" header
        XCTAssertFalse(urlRequest.allHTTPHeaderFields!.isEmpty)
    }

    func testConstructURLRequestFailsWithInvalidQueryParams() throws {
        let baseURL = URL(string: "https://aws.amazon.com")!
        let paramValue = String(
            bytes: [0xd8, 0x00] as [UInt8],
            encoding: String.Encoding.utf16BigEndian
        )!
        let invalidQueryParams: [String: String] = ["param": paramValue]
        XCTAssertThrowsError(
            try RESTOperationRequestUtils.constructURL(
                for: baseURL,
                withPath: "/projects",
                withParams: invalidQueryParams
            )
        )
    }

    func testApplyCustomizeRequestHeaders_withCutomeHeaders_successfullyOverride() {
        var request = URLRequest(url: URL(string: "https://aws.amazon.com")!)
        request.allHTTPHeaderFields = ["Content-Type": "application/json"]
        let headers = ["Content-Type": "text/plain"]
        let requestWithHeaders = RESTOperationRequestUtils.applyCustomizeRequestHeaders(headers, on: request)
        XCTAssertNotNil(requestWithHeaders.allHTTPHeaderFields)
        for (key, value) in headers {
            XCTAssertEqual(requestWithHeaders.allHTTPHeaderFields![key], value)
        }
    }

}

extension RESTRequestUtilsTests {
    private struct ConstructURLTestCase {
        let baseURL: URL
        let path: String?
        var inputParams: [String: String]?
        var expectedOutputParams: [String: String]?

        init(
            baseURL: URL,
            path: String?,
            inputParams: [String: String]? = nil,
            expectedOutputParams: [String: String]? = nil
        ) {
            self.baseURL = baseURL
            self.path = path
            self.inputParams = inputParams
            self.expectedOutputParams = expectedOutputParams
        }

        struct Params {
            let value: [String: String]?
            static let unencodedEmail = Params(value: ["author": "john@email.com"])
            static let encodedEmail = Params(value: ["author": "john%40email.com"])
            static let unencodedDate = Params(value: ["created": "2021-06-18T09:00:00Z"])
            static let encodedDate = Params(value: ["created": "2021-06-18T09%3A00%3A00Z"])
            static let unencodedVarious = Params(
                value: [
                    "created": "2021-06-18T09%3A00%3A00Z",
                    "param1": "query%21"
                ]
            )
            static let encodedVarious = Params(
                value: [
                    "created": "2021-06-18T09:00:00Z",
                    "param1": "query!"
                ]
            )
            static let nilCase = Params(value: nil)
        }

        func withInput(_ inputParams: Params) -> Self {
            var copy = self
            copy.inputParams = inputParams.value
            return self
        }

        func expecting(_ outputParams: Params) -> Self {
            var copy = self
            copy.expectedOutputParams = outputParams.value
            return self
        }
    }
}
