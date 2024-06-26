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

        let decoratedURLRequest = await interceptor.interceptConnection(url: URL(string: "https://example.com")!)
        guard let decoratedURL = decoratedURLRequest.url,
              let components = URLComponents(url: decoratedURL, resolvingAgainstBaseURL: false) else {
            XCTFail("Failed to get url components from decorated URL")
            return
        }

        guard let payloadString =
                try? components.queryItems?.first(where: { $0.name == "payload" })?.value?.base64DecodedString()
        else {
            XCTFail("Failed to extract payload field from query string")
            return
        }

        XCTAssertEqual("{}", payloadString)

        guard let authorizationHeaderString = try? decoratedURLRequest.value(forHTTPHeaderField: "Authorization")?.base64DecodedString()
        else {
            XCTFail("Failed to extract authorization field from headers")
            return
        }
        guard let authString = try? JSONDecoder().decode(JSONValue.self, from: authorizationHeaderString.data(using: .utf8)!)
        else {
            XCTFail("Failed to decode query header to json object")
            return
        }
        XCTAssertEqual(authTokenProvider.authToken, authString.Authorization?.stringValue)
        XCTAssertEqual("example.com", authString.host?.stringValue)
    }

    func testInterceptConnection_withAuthTokenProviderFailed_appendEmptyAuthHeaderToQuery() async {
        let authTokenProvider = MockAuthTokenProviderFailed()
        let interceptor = AuthTokenInterceptor(authTokenProvider: authTokenProvider)

        let decoratedURLRequest = await interceptor.interceptConnection(url: URL(string: "https://example.com")!)
        guard let decoratedURL = decoratedURLRequest.url,
              let components = URLComponents(url: decoratedURL, resolvingAgainstBaseURL: false) else {
            XCTFail("Failed to get url components from decorated URL")
            return
        }

        guard let payloadString =
                try? components.queryItems?.first(where: { $0.name == "payload" })?.value?.base64DecodedString()
        else {
            XCTFail("Failed to extract payload field from query string")
            return
        }

        XCTAssertEqual("{}", payloadString)

        guard let authorizationHeaderString = try? decoratedURLRequest.value(forHTTPHeaderField: "Authorization")?.base64DecodedString()
        else {
            XCTFail("Failed to extract authorization field from headers")
            return
        }
        guard let authString = try? JSONDecoder().decode(JSONValue.self, from: authorizationHeaderString.data(using: .utf8)!)
        else {
            XCTFail("Failed to decode query header to json object")
            return
        }
        XCTAssertEqual("", authString.Authorization?.stringValue)
        XCTAssertEqual("example.com", authString.host?.stringValue)
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
