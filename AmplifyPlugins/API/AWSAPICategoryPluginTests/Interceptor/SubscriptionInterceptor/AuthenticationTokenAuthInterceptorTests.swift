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

    func testAuthenticationTokenInterceptor() throws {
        let url = URL(string: "http://awssubscriptionurl.ca")!
        let request = AppSyncConnectionRequest(url: url)
        let interceptor = AuthenticationTokenAuthInterceptor(authTokenProvider: TestAuthTokenProvider())
        let interceptedRequest = interceptor.interceptConnection(request, for: url)

        XCTAssertNotNil(interceptedRequest.url.query)
    }

    func testDoesNotAddAuthHeaderIfTokenProviderReturnsError() throws {
        let url = URL(string: "http://awssubscriptionurl.ca")!
        let request = AppSyncConnectionRequest(url: url)
        let interceptor = AuthenticationTokenAuthInterceptor(authTokenProvider: TestFailingAuthTokenProvider())
        let interceptedRequest = interceptor.interceptConnection(request, for: url)

        XCTAssertNil(interceptedRequest.url.query)
    }
}


// MARK: - Test token providers
private class TestAuthTokenProvider: AmplifyAuthTokenProvider {
    let authToken = "token"
    func getLatestAuthToken() -> Result<AuthToken, Error> {
        .success(authToken)
    }
}

private class TestFailingAuthTokenProvider: AmplifyAuthTokenProvider {
    let authToken = "token"
    func getLatestAuthToken() -> Result<AuthToken, Error> {
        let error = APIError.networkError("Token error")
        return .failure(error)
    }
}
