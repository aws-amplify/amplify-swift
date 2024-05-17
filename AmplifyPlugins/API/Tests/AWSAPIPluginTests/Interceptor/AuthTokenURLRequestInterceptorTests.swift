//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import InternalAmplifyCredentials
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin

class AuthTokenURLRequestInterceptorTests: XCTestCase {
    func testAuthTokenInterceptor() async throws {
        let mockTokenProvider = MockTokenProvider()
        let interceptor = AuthTokenURLRequestInterceptor(authTokenProvider: mockTokenProvider)
        let request = RESTOperationRequestUtils.constructURLRequest(
            with: URL(string: "http://anapiendpoint.ca")!,
            operationType: .get,
            requestPayload: nil
        )

        guard let headers = try await interceptor.intercept(request).allHTTPHeaderFields else {
            XCTFail("Failed retrieving headers")
            return
        }

        XCTAssertEqual(headers["Authorization"], mockTokenProvider.authorizationToken)
        XCTAssertNotNil(headers[URLRequestConstants.Header.contentType])
        XCTAssertNotNil(headers[URLRequestConstants.Header.xAmzDate])
        XCTAssertNotNil(headers[URLRequestConstants.Header.userAgent])
    }
    
    func testAuthTokenInterceptor_ThrowsInvalid() async throws {
        let mockTokenProvider = MockTokenProvider()
        let interceptor = AuthTokenURLRequestInterceptor(authTokenProvider: mockTokenProvider,
                                                         isTokenExpired: { _ in return true })
        let request = RESTOperationRequestUtils.constructURLRequest(
            with: URL(string: "http://anapiendpoint.ca")!,
            operationType: .get,
            requestPayload: nil
        )
        
        do {
            _ = try await interceptor.intercept(request).allHTTPHeaderFields
        } catch {
            guard case .operationError(let description, _, let underlyingError) = error as? APIError,
               let authError = underlyingError as? AuthError,
               case .sessionExpired = authError else {
                XCTFail("Should be API.operationError with underlying AuthError.sessionExpired")
                return
            }
        }
    }
}

// MARK: - Mocks
extension AuthTokenURLRequestInterceptorTests {
    class MockTokenProvider: AuthTokenProvider {
        let authorizationToken = "authorizationToken"
        
        func getUserPoolAccessToken() async throws -> String {
            authorizationToken
        }
    }
}
