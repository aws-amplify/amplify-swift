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

    func testInterceptConnection_withAuthTokenProvider_appendCorrectAuthHeaderToQuery() async {
        let authTokenProvider = MockAuthTokenProvider()
        let interceptor = AuthTokenInterceptor(authTokenProvider: authTokenProvider)

        let decoratedURL = await interceptor.interceptConnection(url: URL(string: "https://example.com")!)
        guard let components = URLComponents(url: decoratedURL, resolvingAgainstBaseURL: false) else {
            XCTFail("Failed to get url components from decorated URL")
            return
        }

        guard let queryHeaderString =
                try? components.queryItems?.first(where: { $0.name == "header" })?.value?.base64DecodedString()
        else {
            XCTFail("Failed to extract header field from query string")
            return
        }

        guard let queryHeader = try? JSONDecoder().decode(JSONValue.self, from: queryHeaderString.data(using: .utf8)!)
        else {
            XCTFail("Failed to decode query header to json object")
            return
        }
        XCTAssertEqual(authTokenProvider.authToken, queryHeader.Authorization?.stringValue)
        XCTAssertEqual("example.com", queryHeader.host?.stringValue)
    }

    func testInterceptConnection_withAuthTokenProviderFailed_appendEmptyAuthHeaderToQuery() async {
        let authTokenProvider = MockAuthTokenProviderFailed()
        let interceptor = AuthTokenInterceptor(authTokenProvider: authTokenProvider)

        let decoratedURL = await interceptor.interceptConnection(url: URL(string: "https://example.com")!)
        guard let components = URLComponents(url: decoratedURL, resolvingAgainstBaseURL: false) else {
            XCTFail("Failed to get url components from decorated URL")
            return
        }

        guard let queryHeaderString =
                try? components.queryItems?.first(where: { $0.name == "header" })?.value?.base64DecodedString()
        else {
            XCTFail("Failed to extract header field from query string")
            return
        }

        guard let queryHeader = try? JSONDecoder().decode(JSONValue.self, from: queryHeaderString.data(using: .utf8)!)
        else {
            XCTFail("Failed to decode query header to json object")
            return
        }
        XCTAssertEqual("", queryHeader.Authorization?.stringValue)
        XCTAssertEqual("example.com", queryHeader.host?.stringValue)
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
