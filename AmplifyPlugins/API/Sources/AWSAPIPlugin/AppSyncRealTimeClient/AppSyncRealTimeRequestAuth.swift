//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

public enum AppSyncRealTimeRequestAuth {
    case authToken(AuthToken)
    case apiKey(ApiKey)
    case iam(IAM)

    public struct AuthToken {
        let host: String
        let authToken: String
    }

    public struct ApiKey {
        let host: String
        let apiKey: String
        let amzDate: String
    }

    public struct IAM {
        let host: String
        let authToken: String
        let securityToken: String
        let amzDate: String
    }

    public struct URLQuery {
        let header: AppSyncRealTimeRequestAuth
        let payload: String

        init(header: AppSyncRealTimeRequestAuth, payload: String = "{}") {
            self.header = header
            self.payload = payload
        }

        func withBaseURL(_ url: URL, encoder: JSONEncoder? = nil) -> URL {
            let jsonEncoder: JSONEncoder = encoder ?? JSONEncoder()
            guard let headerJsonData = try? jsonEncoder.encode(header) else {
                return url
            }

            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            else {
                return url
            }

            urlComponents.queryItems = [
                URLQueryItem(name: "header", value: headerJsonData.base64EncodedString()),
                URLQueryItem(name: "payload", value: try? payload.base64EncodedString())
            ]

            return urlComponents.url ?? url
        }
    }
}

extension AppSyncRealTimeRequestAuth: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .apiKey(let apiKey):
            try container.encode(apiKey)
        case .authToken(let cognito):
            try container.encode(cognito)
        case .iam(let iam):
            try container.encode(iam)
        }
    }
}

extension AppSyncRealTimeRequestAuth.AuthToken: Encodable {
    enum CodingKeys: String, CodingKey {
        case host
        case authToken = "Authorization"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(host, forKey: .host)
        try container.encode(authToken, forKey: .authToken)
    }
}

extension AppSyncRealTimeRequestAuth.ApiKey: Encodable {
    enum CodingKeys: String, CodingKey {
        case host
        case apiKey = "x-api-key"
        case amzDate = "x-amz-date"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(host, forKey: .host)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(amzDate, forKey: .amzDate)
    }
}

extension AppSyncRealTimeRequestAuth.IAM: Encodable {
    enum CodingKeys: String, CodingKey {
        case host
        case accept
        case contentType = "content-type"
        case authToken = "Authorization"
        case securityToken = "X-Amz-Security-Token"
        case contentEncoding = "content-encoding"
        case amzDate = "x-amz-date"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(host, forKey: .host)
        try container.encode("application/json, text/javascript", forKey: .accept)
        try container.encode("application/json; charset=UTF-8", forKey: .contentType)
        try container.encode("amz-1.0", forKey: .contentEncoding)
        try container.encode(securityToken, forKey: .securityToken)
        try container.encode(authToken, forKey: .authToken)
        try container.encode(amzDate, forKey: .amzDate)
    }
}
