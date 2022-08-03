//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AppSyncRealTimeClient
@testable import AWSAPIPlugin
@testable import AmplifyTestCommon

class AuthenticationTokenAuthInterceptorTests: XCTestCase {

    func testAuthenticationTokenInterceptor() async throws {
        let url = URL(string: "http://awssubscriptionurl.ca")!
        let request = AppSyncConnectionRequest(url: url)
        let interceptor = AuthenticationTokenAuthInterceptor(authTokenProvider: TestAuthTokenProvider())
        let interceptedRequest = await interceptor.interceptConnection(request, for: url)

        XCTAssertNotNil(interceptedRequest.url.query)
    }

    func testDoesNotAddAuthHeaderIfTokenProviderReturnsError() async throws {
        let url = URL(string: "http://awssubscriptionurl.ca")!
        let request = AppSyncConnectionRequest(url: url)
        let interceptor = AuthenticationTokenAuthInterceptor(authTokenProvider: TestFailingAuthTokenProvider())
        let interceptedRequest = await interceptor.interceptConnection(request, for: url)

        XCTAssertNil(interceptedRequest.url.query)
    }
}

// MARK: - Test token providers
private class TestAuthTokenProvider: AmplifyAuthTokenProvider {
    let authToken = "token"
    
    func getUserPoolAccessToken() async throws -> String {
        authToken
    }
}

private class TestFailingAuthTokenProvider: AmplifyAuthTokenProvider {
    
    let authToken = "token"
    
    func getUserPoolAccessToken() async throws -> String {
        throw "Token error"
    }
}
