//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPIPlugin
@testable import AmplifyTestCommon

class AuthenticationTokenAuthInterceptorTests: XCTestCase {

    func testAuthenticationTokenInterceptor() async throws {
        let url = URL(string: "http://awssubscriptionurl.ca")!
        let interceptor = CognitoAuthInterceptor(authTokenProvider: TestAuthTokenProvider())
        let interceptedUrl = await interceptor.interceptConnection(url: url)

        XCTAssertNotNil(interceptedUrl.query)
    }

    func testDoesNotAddAuthHeaderIfTokenProviderReturnsError() async throws {
        let url = URL(string: "http://awssubscriptionurl.ca")!
        let interceptor = CognitoAuthInterceptor(authTokenProvider: TestFailingAuthTokenProvider())
        let interceptedUrl = await interceptor.interceptConnection(url: url)

        XCTAssertNil(interceptedUrl.query)
    }
}

// MARK: - Test token providers
private class TestAuthTokenProvider: AmplifyAuthTokenProvider {
    
    let authToken = "token"
    
    func getLatestAuthToken() async throws -> String {
        authToken
    }
}

private class TestFailingAuthTokenProvider: AmplifyAuthTokenProvider {
    
    let authToken = "token"
    
    func getLatestAuthToken() async throws -> String {
        throw "Token error"
    }
}
