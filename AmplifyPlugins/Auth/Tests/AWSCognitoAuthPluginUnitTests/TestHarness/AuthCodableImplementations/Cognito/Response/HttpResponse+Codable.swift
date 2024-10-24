//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import SmithyHTTPAPI

extension SmithyHTTPAPI.HTTPResponse: Codable { }

enum HTTPResponseCodingKeys: String, CodingKey {
    case statusCode = "statusCode"
}

extension Encodable where Self: SmithyHTTPAPI.HTTPResponse {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: HTTPResponseCodingKeys.self)
        try container.encode(statusCode.rawValue, forKey: .statusCode)
    }
}

extension Decodable where Self: SmithyHTTPAPI.HTTPResponse {

    public init(from decoder: Decoder) throws {

        let containerValues = try decoder.container(keyedBy: HTTPResponseCodingKeys.self)
        let httpStatusCode = try containerValues.decodeIfPresent(Int.self, forKey: .statusCode)
        self = SmithyHTTPAPI.HTTPResponse(
            body: .empty,
            statusCode: SmithyHTTPAPI.HTTPStatusCode(rawValue: httpStatusCode ?? 404) ?? .notFound
        ) as! Self
    }
}
