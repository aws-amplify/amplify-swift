//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import Amplify
@testable import AWSAPIPlugin
@testable @_spi(WebSocket) import AWSPluginsCore

class CognitoAuthInterceptorTests: XCTestCase {

    func testInterceptConnection_withAuthTokenProvider_appendCorrectAuthHeader() async {
        let authTokenProvider = MockAuthTokenProvider()
        let interceptor = AuthTokenInterceptor(authTokenProvider: authTokenProvider)

        let decoratedURLRequest = await interceptor.interceptConnection(request: URLRequest(url:URL(string: "https://example.com")!))

        XCTAssertEqual(authTokenProvider.authToken, decoratedURLRequest.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual("example.com", decoratedURLRequest.value(forHTTPHeaderField: "host"))
    }

    func testInterceptConnection_withAuthTokenProviderFailed_appendEmptyAuthHeader() async {
        let authTokenProvider = MockAuthTokenProviderFailed()
        let interceptor = AuthTokenInterceptor(authTokenProvider: authTokenProvider)

        let decoratedURLRequest = await interceptor.interceptConnection(request: URLRequest(url:URL(string: "https://example.com")!))

        XCTAssertEqual("", decoratedURLRequest.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual("example.com", decoratedURLRequest.value(forHTTPHeaderField: "host"))
    }

    func testInterceptRequest_withAuthTokenProvider_appendCorrectAuthInfoToPayload() async {
        let authTokenProvider = MockAuthTokenProvider()
        let interceptor = AuthTokenInterceptor(authTokenProvider: authTokenProvider)
        let decoratedRequest = await interceptor.interceptRequest(
            event: .start(.init(id: UUID().uuidString, data: UUID().uuidString, auth: nil)),
            url: URL(string: "https://example.com")!
        )

        guard case let .start(decoratedAuth) = decoratedRequest else {
            XCTFail("Failed to extract decoratedAuth info")
            return
        }

        guard case let .some(.authToken(authInfo))  = decoratedAuth.auth else {
            XCTFail("Failed to extract authInfo from decoratedAuth")
            return
        }

        XCTAssertEqual(authTokenProvider.authToken, authInfo.authToken)
        XCTAssertEqual("example.com", authInfo.host)
    }

    func testInterceptRequest_withAuthTokenProviderFailed_appendEmptyAuthInfoToPayload() async {
        let authTokenProvider = MockAuthTokenProviderFailed()
        let interceptor = AuthTokenInterceptor(authTokenProvider: authTokenProvider)
        let decoratedRequest = await interceptor.interceptRequest(
            event: .start(.init(id: UUID().uuidString, data: UUID().uuidString, auth: nil)),
            url: URL(string: "https://example.com")!
        )

        guard case let .start(decoratedAuth) = decoratedRequest else {
            XCTFail("Failed to extract decoratedAuth info")
            return
        }

        guard case let .some(.authToken(authInfo))  = decoratedAuth.auth else {
            XCTFail("Failed to extract authInfo from decoratedAuth")
            return
        }

        XCTAssertEqual("", authInfo.authToken)
        XCTAssertEqual("example.com", authInfo.host)
    }
}

fileprivate class MockAuthTokenProvider: AmplifyAuthTokenProvider {
    let authToken = UUID().uuidString
    func getLatestAuthToken() async throws -> String {
        return authToken
    }
}

fileprivate class MockAuthTokenProviderFailed: AmplifyAuthTokenProvider {
    let authToken = UUID().uuidString
    func getLatestAuthToken() async throws -> String {
        throw "Intended"
    }
}
