//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AppSyncRealTimeClient
@testable import AWSPluginsTestCommon
@testable import AWSAPIPlugin
@testable import AmplifyTestCommon

class IAMAuthInterceptorTests: XCTestCase {

    func testIAMAuthenticationHeader() throws {
        let expectedAdditionalHeaders = ["extra-header": "headerValue"]
        let authHeader = IAMAuthenticationHeader(host: "host",
                                                 authorization: "auth",
                                                 securityToken: "token",
                                                 amzDate: "date",
                                                 accept: "accept",
                                                 contentEncoding: "encoding",
                                                 contentType: "type",
                                                 additionalHeaders: expectedAdditionalHeaders)
        XCTAssertEqual(authHeader.authorization, "auth")
        XCTAssertEqual(authHeader.securityToken, "token")
        XCTAssertEqual(authHeader.amzDate, "date")
        XCTAssertEqual(authHeader.accept, "accept")
        XCTAssertEqual(authHeader.contentEncoding, "encoding")
        XCTAssertEqual(authHeader.contentType, "type")
        XCTAssertEqual(authHeader.additionalHeaders, expectedAdditionalHeaders)
    }

    func testIAMAuthenticationHeaderEncodable() throws {
        let authHeader = IAMAuthenticationHeader(host: "host",
                                                 authorization: "auth",
                                                 securityToken: "token",
                                                 amzDate: "date",
                                                 accept: "accept",
                                                 contentEncoding: "encoding",
                                                 contentType: "type",
                                                 additionalHeaders: nil)

        let encoder = JSONEncoder()
        let serializedJSON = try encoder.encode(authHeader)
        let decoder = JSONDecoder()
        let json = try decoder.decode(JSONValue.self, from: serializedJSON)

        guard case let .object(jsonObject) = json else {
            XCTFail("Failed to get JSON object")
            return
        }
        XCTAssertEqual(jsonObject["host"], "host")
        XCTAssertEqual(jsonObject[SubscriptionConstants.authorizationkey], "auth")
        XCTAssertEqual(jsonObject[RealtimeProviderConstants.iamSecurityTokenKey], "token")
        XCTAssertEqual(jsonObject[RealtimeProviderConstants.amzDate], "date")
        XCTAssertEqual(jsonObject[RealtimeProviderConstants.acceptKey], "accept")
        XCTAssertEqual(jsonObject[RealtimeProviderConstants.contentEncodingKey], "encoding")
        XCTAssertEqual(jsonObject[RealtimeProviderConstants.contentTypeKey], "type")
        XCTAssertEqual(jsonObject.count, 7)
    }

    func testIAMAuthenticationHeaderEncodableWithAdditionalHeaders() throws {
        let expectedAdditionalHeaders = ["extra-header": "headerValue"]
        let authHeader = IAMAuthenticationHeader(host: "host",
                                                 authorization: "auth",
                                                 securityToken: "token",
                                                 amzDate: "date",
                                                 accept: "accept",
                                                 contentEncoding: "encoding",
                                                 contentType: "type",
                                                 additionalHeaders: expectedAdditionalHeaders)

        let encoder = JSONEncoder()
        let serializedJSON = try encoder.encode(authHeader)
        let decoder = JSONDecoder()
        let json = try decoder.decode(JSONValue.self, from: serializedJSON)

        guard case let .object(jsonObject) = json else {
            XCTFail("Failed to get JSON object")
            return
        }
        XCTAssertEqual(jsonObject["host"], "host")
        XCTAssertEqual(jsonObject[SubscriptionConstants.authorizationkey], "auth")
        XCTAssertEqual(jsonObject[RealtimeProviderConstants.iamSecurityTokenKey], "token")
        XCTAssertEqual(jsonObject[RealtimeProviderConstants.amzDate], "date")
        XCTAssertEqual(jsonObject[RealtimeProviderConstants.acceptKey], "accept")
        XCTAssertEqual(jsonObject[RealtimeProviderConstants.contentEncodingKey], "encoding")
        XCTAssertEqual(jsonObject[RealtimeProviderConstants.contentTypeKey], "type")
        XCTAssertEqual(jsonObject["extra-header"], "headerValue")
        XCTAssertEqual(jsonObject.count, 8)
    }

    func testInterceptConnection() async {
        let mockAuthService = MockAWSAuthService()
        let interceptor = IAMAuthInterceptor(mockAuthService.getCredentialsProvider(), region: "us-west-2")
        let url = URL(string: "https://abc.appsync-api.us-west-2.amazonaws.com/graphql")!
        let signer = MockAWSSignatureV4Signer()
        guard let authHeader = await interceptor.getAuthHeader(url, with: "payload", signer: signer) else {
            XCTFail("Could not get authHeader")
            return
        }

        XCTAssertNotNil(authHeader.authorization)
        XCTAssertNotNil(authHeader.securityToken)
        XCTAssertNotNil(authHeader.amzDate)
        XCTAssertEqual(authHeader.accept, "application/json, text/javascript")
        XCTAssertEqual(authHeader.contentEncoding, "amz-1.0")
        XCTAssertEqual(authHeader.contentType, "application/json; charset=UTF-8")
        XCTAssertNil(authHeader.additionalHeaders)
    }
}
