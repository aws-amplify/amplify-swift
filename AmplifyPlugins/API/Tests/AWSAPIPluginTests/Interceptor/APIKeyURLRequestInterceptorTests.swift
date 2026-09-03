//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class APIKeyURLRequestInterceptorTests: XCTestCase, @unchecked Sendable {
    func testAPIKeyInterceptor() {
        let mockAPIKeyProvider = MockAPIKeyProvider()
        let interceptor = APIKeyURLRequestInterceptor(apiKeyProvider: mockAPIKeyProvider)
        let request = URLRequest(url: URL(string: "http://anapiendpoint.ca")!)
        guard let headers = interceptor.intercept(request).allHTTPHeaderFields else {
            XCTFail("Failed retrieving headers")
            return
        }

        XCTAssertTrue(mockAPIKeyProvider.getAPIKeyCalled)
        XCTAssertEqual(headers[URLRequestConstants.Header.xApiKey], mockAPIKeyProvider.apiKey)
        XCTAssertNotNil(headers[URLRequestConstants.Header.userAgent])
    }
}

// MARK: - Mocks
extension APIKeyURLRequestInterceptorTests {
    private class MockAPIKeyProvider: APIKeyProvider {
        let apiKey = "api-key"
        var getAPIKeyCalled = false

        func getAPIKey() -> String {
            getAPIKeyCalled = true
            return apiKey
        }
    }
}
