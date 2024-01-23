//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
@testable import AWSAPIPlugin

class AppSyncRealTimeRequestAuthTests: XCTestCase {
    var jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    func testAppSyncRealTimeRequestAuth_encodeCognito() {
        let cognitoAuth = AppSyncRealTimeRequestAuth.CognitoAuth(host: "example.com", authToken: "token")
        XCTAssertEqual(toJson(cognitoAuth), """
        {"Authorization":"token","host":"example.com"}
        """)

        let cognitoRequestAuth = AppSyncRealTimeRequestAuth.cognito(.init(host: "example.com", authToken: "token"))
        XCTAssertEqual(toJson(cognitoRequestAuth), """
        {"Authorization":"token","host":"example.com"}
        """)
    }

    func testAppSyncRealTimeRequestAuth_encodStartRequestWithApiKeyAuth() {
        let host = UUID().uuidString
        let apiKey = UUID().uuidString
        let date = UUID().uuidString
        let id = UUID().uuidString
        let data = UUID().uuidString
        let auth: AppSyncRealTimeRequestAuth = .apiKey(.init(host: host, apiKey: apiKey, amzDate: date))
        let request = AppSyncRealTimeRequest.start(
            .init(id: id, data: data, auth: auth)
        )
        let requestJson = toJson(request)
        XCTAssertEqual(requestJson, """
        {
            "id": "\(id)",
            "payload": {
                "data": "\(data)",
                "extensions": {
                    "authorization": {
                        "host": "\(host)",
                        "x-amz-date": "\(date)",
                        "x-api-key": "\(apiKey)"
                    }
                }
            },
            "type": "start"
        }
        """.shrink())
    }

    private func toJson(_ value: Encodable) -> String? {
        return try? String(data: jsonEncoder.encode(value), encoding: .utf8)
    }
}

fileprivate extension String {
    func shrink() -> String {
        return self.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}
