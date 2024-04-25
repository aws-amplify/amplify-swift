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

    func testInterceptConnection_addApiKeySignatureInURLQuery() async {
        let apiKey = UUID().uuidString
        let interceptor = APIKeyAuthInterceptor(apiKey: apiKey)
        let resultUrl = await interceptor.interceptConnection(url: URL(string: "https://example.com")!)
        guard let components = URLComponents(url: resultUrl, resolvingAgainstBaseURL: false) else {
            XCTFail("Failed to decode decorated URL")
            return
        }

        let header = components.queryItems?.first { $0.name == "header" }
        XCTAssertNotNil(header?.value)
        let headerData = try! header?.value!.base64DecodedString().data(using: .utf8)
        let decodedHeader = try! JSONDecoder().decode(JSONValue.self, from: headerData!)
        XCTAssertEqual(decodedHeader["x-api-key"]?.stringValue, apiKey)
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
