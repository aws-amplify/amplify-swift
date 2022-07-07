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

class AuthTokenURLRequestInterceptorTests: XCTestCase {
    func testAuthTokenInterceptor() async throws {
        let mockTokenProvider = MockTokenProvider()
        let interceptor = AuthTokenURLRequestInterceptor(authTokenProvider: mockTokenProvider)
        let request = URLRequest(url: URL(string: "http://anapiendpoint.ca")!)

        guard let headers = try await interceptor.intercept(request).allHTTPHeaderFields else {
            XCTFail("Failed retrieving headers")
            return
        }

        XCTAssertEqual(headers["Authorization"], mockTokenProvider.authorizationToken)
        XCTAssertNotNil(headers[URLRequestConstants.Header.contentType])
        XCTAssertNotNil(headers[URLRequestConstants.Header.xAmzDate])
        XCTAssertNotNil(headers[URLRequestConstants.Header.userAgent])
    }
}

// MARK: - Mocks
extension AuthTokenURLRequestInterceptorTests {
    class MockTokenProvider: AuthTokenProvider {
        let authorizationToken = "authorizationToken"

        func getToken() -> Result<String, AuthError> {
            .success(authorizationToken)
        }
        
        func getUserPoolAccessToken(completion: @escaping (Result<String, AuthError>) -> Void) {
            completion(.success(authorizationToken))
        }
        
        func getUserPoolAccessToken() async throws -> String {
            authorizationToken
        }
    }
}
