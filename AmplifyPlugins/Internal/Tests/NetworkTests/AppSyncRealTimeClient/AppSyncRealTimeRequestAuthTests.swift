//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
@testable import AWSAPIPlugin

class AppSyncRealTimeRequestAuthTests: XCTestCase {
    let host = UUID().uuidString
    let apiKey = UUID().uuidString
    let date = UUID().uuidString
    let id = UUID().uuidString
    let data = UUID().uuidString
    let token = UUID().uuidString

    var jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    func testAppSyncRealTimeRequestAuth_encodeCognito() {
        let cognitoAuth = AppSyncRealTimeRequestAuth.AuthToken(host: host, authToken: token)
        XCTAssertEqual(toJson(cognitoAuth)?.shrink(), """
        {
            "Authorization": "\(token)",
            "host": "\(host)"
        }
        """.shrink())
    }

    func testAppSyncRealTimeRequestAuth_encodeApiKey() {
        let apiKeyAuth = AppSyncRealTimeRequestAuth.ApiKey(host: host, apiKey: apiKey, amzDate: date)
        XCTAssertEqual(toJson(apiKeyAuth)?.shrink(), """
        {
            "host": "\(host)",
            "x-amz-date": "\(date)",
            "x-api-key": "\(apiKey)"
        }
        """.shrink())
    }

    func testAppSyncRealTimeRequestAuth_encodeIAM() {
        let securityToken = UUID().uuidString
        let iamAuth = AppSyncRealTimeRequestAuth.IAM(
            host: host,
            authToken: token,
            securityToken: securityToken,
            amzDate: date
        )

        XCTAssertEqual(toJson(iamAuth)?.shrink(), """
        {
            "accept": "application\\/json, text\\/javascript",
            "Authorization": "\(token)",
            "content-encoding": "amz-1.0",
            "content-type": "application\\/json; charset=UTF-8",
            "host": "\(host)",
            "x-amz-date": "\(date)",
            "X-Amz-Security-Token": "\(securityToken)"
        }
        """.shrink())
    }

    func testAppSyncRealTimeRequestAuth_encodeStartRequestWithCognitoAuth() {
        let auth: AppSyncRealTimeRequestAuth = .authToken(.init(host: host, authToken: token))
        let request = AppSyncRealTimeRequest.start(
            .init(id: id, data: data, auth: auth)
        )
        let requestJson = toJson(request)
        XCTAssertEqual(requestJson?.shrink(), """
        {
            "id": "\(id)",
            "payload": {
                "data": "\(data)",
                "extensions": {
                    "authorization": {
                        "Authorization": "\(token)",
                        "host": "\(host)"
                    }
                }
            },
            "type": "start"
        }
        """.shrink())
    }

    func testAppSyncRealTimeRequestAuth_encodeStartRequestWithApiKeyAuth() {
        let auth: AppSyncRealTimeRequestAuth = .apiKey(.init(host: host, apiKey: apiKey, amzDate: date))
        let request = AppSyncRealTimeRequest.start(
            .init(id: id, data: data, auth: auth)
        )
        let requestJson = toJson(request)
        XCTAssertEqual(requestJson?.shrink(), """
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

    func testAppSyncRealTimeRequestAuth_encodeStartRequestWithIAMAuth() {
        let securityToken = UUID().uuidString
        let iamAuth = AppSyncRealTimeRequestAuth.IAM(
            host: host,
            authToken: token,
            securityToken: securityToken,
            amzDate: date
        )
        let request = AppSyncRealTimeRequest.start(
            .init(id: id, data: data, auth: .iam(iamAuth))
        )
        let requestJson = toJson(request)
        XCTAssertEqual(requestJson?.shrink(), """
        {
            "id": "\(id)",
            "payload": {
                "data": "\(data)",
                "extensions": {
                    "authorization": {
                        "accept": "application\\/json, text\\/javascript",
                        "Authorization": "\(token)",
                        "content-encoding": "amz-1.0",
                        "content-type": "application\\/json; charset=UTF-8",
                        "host": "\(host)",
                        "x-amz-date": "\(date)",
                        "X-Amz-Security-Token": "\(securityToken)"
                    }
                }
            },
            "type": "start"
        }
        """.shrink())
    }

    func testAppSyncRealTimeRequestAuth_URLQueryWithCognitoAuthHeader() {
        let expectedURL = """
        https://example.com?\
        header=eyJBdXRob3JpemF0aW9uIjoiNDk4NTljN2MtNzQwNS00ZDU4LWFmZjctNTJiZ\
        TRiNDczNTU3IiwiaG9zdCI6ImV4YW1wbGUuY29tIn0%3D\
        &payload=e30%3D
        """
        let encodedURL = AppSyncRealTimeRequestAuth.URLQuery(
            header: .authToken(.init(
                host: "example.com",
                authToken: "49859c7c-7405-4d58-aff7-52be4b473557"
            ))
        ).withBaseURL(URL(string: "https://example.com")!, encoder: jsonEncoder)
        XCTAssertEqual(encodedURL.absoluteString, expectedURL)
    }

    func testAppSyncRealTimeRequestAuth_URLQueryWithApiKeyAuthHeader() {
        let expectedURL = """
        https://example.com?\
        header=eyJob3N0IjoiZXhhbXBsZS5jb20iLCJ4LWFtei1kYXRlIjoiOWUwZTJkZjktMmVlNy00NjU5L\
        TgzNjItMWM4ODFlMTE4YzlmIiwieC1hcGkta2V5IjoiNjVlMmZhY2EtOGUxZS00ZDM3LThkYzctNjQ0N\
        2Q5Njk4MjQ3In0%3D\
        &payload=e30%3D
        """
        let encodedURL = AppSyncRealTimeRequestAuth.URLQuery(
            header: .apiKey(.init(
                host: "example.com",
                apiKey: "65e2faca-8e1e-4d37-8dc7-6447d9698247",
                amzDate: "9e0e2df9-2ee7-4659-8362-1c881e118c9f"
            ))
        ).withBaseURL(URL(string: "https://example.com")!, encoder: jsonEncoder)
        XCTAssertEqual(encodedURL.absoluteString, expectedURL)
    }

    func testAppSyncRealTimeRequestAuth_URLQueryWithIAMAuthHeader() {

        let expectedURL = """
        https://example.com?\
        header=eyJhY2NlcHQiOiJhcHBsaWNhdGlvblwvanNvbiwgdGV4dFwvamF2YXNjcmlwdCIsIkF1dGhvcml6YXR\
        pb24iOiJjOWRhZDg5Ny05MGQxLTRhNGMtYTVjOS0yYjM2YTI0NzczNWYiLCJjb250ZW50LWVuY29kaW5nIjoiY\
        W16LTEuMCIsImNvbnRlbnQtdHlwZSI6ImFwcGxpY2F0aW9uXC9qc29uOyBjaGFyc2V0PVVURi04IiwiaG9zdCI\
        6ImV4YW1wbGUuY29tIiwieC1hbXotZGF0ZSI6IjllMGUyZGY5LTJlZTctNDY1OS04MzYyLTFjODgxZTExOGM5Z\
        iIsIlgtQW16LVNlY3VyaXR5LVRva2VuIjoiZTdlNjI2OWUtZmRhMS00ZGUwLThiZGItYmFhN2I2ZGQwYTBkIn0%3D\
        &payload=e30%3D
        """
        let encodedURL = AppSyncRealTimeRequestAuth.URLQuery(
            header: .iam(.init(
                host: "example.com",
                authToken: "c9dad897-90d1-4a4c-a5c9-2b36a247735f",
                securityToken: "e7e6269e-fda1-4de0-8bdb-baa7b6dd0a0d",
                amzDate: "9e0e2df9-2ee7-4659-8362-1c881e118c9f"))
        ).withBaseURL(URL(string: "https://example.com")!, encoder: jsonEncoder)
        XCTAssertEqual(encodedURL.absoluteString, expectedURL)
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
