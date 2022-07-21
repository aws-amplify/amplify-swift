//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin

class APIKeyURLRequestInterceptorTests: XCTestCase {
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
