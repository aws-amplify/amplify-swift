//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AppSyncRealTimeClient
import AWSCore
@testable import AWSAPICategoryPlugin
@testable import AmplifyTestCommon

class IAMAuthInterceptorTests: XCTestCase {

    func testIAMAuthenticationHeader() throws {
        let expectedRemainingHeaders = ["extra-header": "headerValue"]
        let authHeader = IAMAuthenticationHeader(host: "host",
                                                 authorization: "auth",
                                                 securityToken: "token",
                                                 amzDate: "date",
                                                 accept: "accept",
                                                 contentEncoding: "encoding",
                                                 contentType: "type",
                                                 remainingHeaders: expectedRemainingHeaders)
        XCTAssertEqual(authHeader.authorization, "auth")
        XCTAssertEqual(authHeader.securityToken, "token")
        XCTAssertEqual(authHeader.amzDate, "date")
        XCTAssertEqual(authHeader.accept, "accept")
        XCTAssertEqual(authHeader.contentEncoding, "encoding")
        XCTAssertEqual(authHeader.contentType, "type")
        XCTAssertEqual(authHeader.remainingHeaders, expectedRemainingHeaders)
    }

    func testIAMAuthenticationHeaderEncodable() throws {
        let expectedRemainingHeaders = ["extra-header": "headerValue"]
        let authHeader = IAMAuthenticationHeader(host: "host",
                                                 authorization: "auth",
                                                 securityToken: "token",
                                                 amzDate: "date",
                                                 accept: "accept",
                                                 contentEncoding: "encoding",
                                                 contentType: "type",
                                                 remainingHeaders: expectedRemainingHeaders)

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
    }

    func testInterceptConnection() {
        let mockAuthService = MockAWSAuthService()
        let interceptor = IAMAuthInterceptor(mockAuthService.getCredentialsProvider(), region: .USWest2)
        let url = URL(string: "https://abc.appsync-api.us-west-2.amazonaws.com/graphql")!
        let request = NSMutableURLRequest(url: url)
        request.addValue("headerValue", forHTTPHeaderField: "extra-header")
        let signer = MockAWSSignatureV4Signer()
        let authHeader = interceptor.getAuthHeader(host: "host",
                                               mutableRequest: request,
                                               signer: signer,
                                               amzDate: "date",
                                               payload: "payload")

        XCTAssertNotNil(authHeader.authorization)
        XCTAssertNotNil(authHeader.securityToken)
        XCTAssertEqual(authHeader.amzDate, "date")
        XCTAssertEqual(authHeader.accept, "application/json, text/javascript")
        XCTAssertEqual(authHeader.contentEncoding, "amz-1.0")
        XCTAssertEqual(authHeader.contentType, "application/json; charset=UTF-8")
        XCTAssertEqual(authHeader.remainingHeaders, ["extra-header": "headerValue"])
    }
}
