//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSAPICategoryPlugin

class RESTRequestUtilsTests: XCTestCase {
    private struct ConstructURLTestCase {
        let baseURL: URL
        let path: String?
        let queryParameters: [String: String]?
        let expectedURL: String

        init(_ url: String, _ path: String?, _ params: [String: String]?, expected: String) {
            self.baseURL = URL(string: url)!
            self.path = path
            self.queryParameters = params
            self.expectedURL = expected
        }
    }

    func testConstructURL() throws {
        let baseURL = "https://aws.amazon.com"
        let testCases: [ConstructURLTestCase] = [
            ConstructURLTestCase(baseURL,
                              "/projects",
                              ["author": "john@email.com"],
                              expected: "https://aws.amazon.com/projects?author=john%40email.com"),
            ConstructURLTestCase(baseURL,
                              "/projects",
                              ["created": "2021-06-18T09:00:00Z"],
                              expected: baseURL + "/projects?created=2021-06-18T09%3A00%3A00Z"),
            ConstructURLTestCase(baseURL,
                                 "/projects",
                                 [
                                  "created": "2021-06-18T09:00:00Z",
                                  "param1": "query!",
                                  "param2": "!*';:@&=+$,/?%#[]()\\"],
                                 // swiftlint:disable line_length
                                 expected: baseURL + "/projects?created=2021-06-18T09%3A00%3A00Z&param1=query%21&param2=%21%2A%27%3B%3A%40%26%3D%2B%24%2C%2F%3F%25%23%5B%5D%28%29%5C"),
            ConstructURLTestCase(baseURL,
                                 "/projects",
                                 nil,
                                 expected: baseURL + "/projects"),
            ConstructURLTestCase(baseURL, nil, nil, expected: baseURL)
        ]

        for (index, test) in testCases.enumerated() {
            let result = try RESTOperationRequestUtils.constructURL(
                for: test.baseURL,
                with: test.path,
                with: test.queryParameters)
            XCTAssertEqual(result.absoluteString, test.expectedURL, "Failed test case \(index)")
        }
    }

    func testConstructURLRequest() throws {
        let baseURL = URL(string: "https://aws.amazon.com")!
        let url = try RESTOperationRequestUtils.constructURL(for: baseURL, with: "/projects", with: nil)
        let urlRequest = RESTOperationRequestUtils.constructURLRequest(with: url, operationType: .get, headers: nil, requestPayload: nil)

        XCTAssertEqual(urlRequest.httpMethod, RESTOperationType.get.rawValue)

        // a REST operation request should always have at least a "content-type" header
        XCTAssertFalse(urlRequest.allHTTPHeaderFields!.isEmpty)
    }
}
