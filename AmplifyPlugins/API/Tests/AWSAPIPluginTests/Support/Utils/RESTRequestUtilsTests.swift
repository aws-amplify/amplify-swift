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
    private struct ConstructURLTestCase {
        let baseURL: URL
        let path: String?
        let queryParameters: [String: String]?
        let expectedParameters: [String: String]?

        init(_ url: String,
             _ path: String?,
             _ params: [String: String]?,
             expectedParameters: [String: String]?) {
            self.baseURL = URL(string: url)!
            self.path = path
            self.queryParameters = params
            self.expectedParameters = expectedParameters
        }
    }

    private func assertQueryParameters(testCase: Int, withURL url: URL, expected: [String: String]?) throws {
        var queryParams: [String: String] = [:]
        url.query?.split(separator: "&").forEach {
            let components = $0.split(separator: "=")
            if let name = components.first, let value = components.last {
                queryParams[String(name)] = String(value)
            }
        }

        guard let expected = expected else {
            XCTAssertTrue(queryParams.isEmpty,
                          "Test \(testCase): Unexpected query items found \(queryParams)")
            return
        }
        XCTAssertEqual(queryParams, expected, "Test \(testCase): query params mismatch")
    }

    func testConstructURL() throws {
        let baseURL = "https://aws.amazon.com"
        let path = "/projects"
        let testCases: [ConstructURLTestCase] = [
            ConstructURLTestCase(baseURL,
                                 path,
                              ["author": "john@email.com"],
                              expectedParameters: ["author": "john%40email.com"]),
            ConstructURLTestCase(baseURL,
                                 path,
                              ["created": "2021-06-18T09:00:00Z"],
                              expectedParameters: ["created": "2021-06-18T09%3A00%3A00Z"]),
            ConstructURLTestCase(baseURL,
                                 path,
                                 [
                                  "created": "2021-06-18T09:00:00Z",
                                  "param1": "query!",
                                  "param2": "!*';:@&=+$,/?%#[]()\\"],
                                 expectedParameters: [
                                    "created": "2021-06-18T09%3A00%3A00Z",
                                    "param1": "query%21",
                                    "param2": "%21%2A%27%3B%3A%40%26%3D%2B%24%2C%2F%3F%25%23%5B%5D%28%29%5C"]),
            ConstructURLTestCase(baseURL,
                                 path,
                                 nil,
                                 expectedParameters: nil),
            ConstructURLTestCase(baseURL, nil, nil, expectedParameters: nil),
            ConstructURLTestCase(baseURL,
                                 path,
                                 ["author": "john%40email.com"],
                                 expectedParameters: ["author": "john%40email.com"])
        ]
        for (index, test) in testCases.enumerated() {
            let resultURL = try RESTOperationRequestUtils.constructURL(
                for: test.baseURL,
                with: test.path,
                with: test.queryParameters)
            try assertQueryParameters(testCase: index, withURL: resultURL, expected: test.expectedParameters)
        }
    }

    func testConstructURLRequest() throws {
        let baseURL = URL(string: "https://aws.amazon.com")!
        let url = try RESTOperationRequestUtils.constructURL(for: baseURL, with: "/projects", with: nil)
        let urlRequest = RESTOperationRequestUtils.constructURLRequest(with: url,
                                                                       operationType: .get,
                                                                       headers: nil,
                                                                       requestPayload: nil)

        XCTAssertEqual(urlRequest.httpMethod, RESTOperationType.get.rawValue)

        // a REST operation request should always have at least a "content-type" header
        XCTAssertFalse(urlRequest.allHTTPHeaderFields!.isEmpty)
    }

    func testConstructURLRequestFailsWithInvalidQueryParams() throws {
        let baseURL = URL(string: "https://aws.amazon.com")!
        let paramValue = String(
            bytes: [0xd8, 0x00] as [UInt8],
            encoding: String.Encoding.utf16BigEndian)!
        let invalidQueryParams: [String: String] = ["param": paramValue]
        XCTAssertThrowsError(try RESTOperationRequestUtils.constructURL(for: baseURL,
                                                             with: "/projects",
                                                             with: invalidQueryParams))
    }
}
