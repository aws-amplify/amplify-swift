//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import Amplify
@testable import AWSAPIPlugin

class APIKeyAuthInterceptorTests: XCTestCase {

    func testInterceptConnection_addApiKeyInRequestHeader() async {
        let apiKey = UUID().uuidString
        let interceptor = APIKeyAuthInterceptor(apiKey: apiKey)
        let resultUrlRequest = await interceptor.interceptConnection(request: URLRequest(url: URL(string: "https://example.com")!))
        
        let header = resultUrlRequest.value(forHTTPHeaderField: "x-api-key")
        XCTAssertEqual(header, apiKey)
    }

    func testInterceptRequest_appendAuthInfoInPayload() async {
        let apiKey = UUID().uuidString
        let interceptor = APIKeyAuthInterceptor(apiKey: apiKey)
        let decoratedRequest = await interceptor.interceptRequest(
            event: AppSyncRealTimeRequest.start(.init(
                id: UUID().uuidString,
                data: "",
                auth: nil
            )),
            url: URL(string: "https://example.appsync-realtime-api.amazonaws.com")!
        )
        guard case let .start(request) = decoratedRequest else {
            XCTFail("Request should be a start request")
            return
        }

        XCTAssertNotNil(request.auth)
        guard case let .apiKey(apiKeyInfo) = request.auth! else {
            XCTFail("Auth should be api key")
            return
        }

        XCTAssertEqual(apiKeyInfo.apiKey, apiKey)
        XCTAssertEqual(apiKeyInfo.host, "example.appsync-api.amazonaws.com")
    }
}
