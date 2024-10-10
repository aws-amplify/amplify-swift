//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension HttpResponse: Codable { }

enum HttpResponseCodingKeys: String, CodingKey {
    case statusCode
}

public extension Encodable where Self: HttpResponse {

    func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: HttpResponseCodingKeys.self)
        try container.encode(statusCode.rawValue, forKey: .statusCode)
    }
}

public extension Decodable where Self: HttpResponse {

    init(from decoder: Decoder) throws {

        let containerValues = try decoder.container(keyedBy: HttpResponseCodingKeys.self)
        let httpStatusCode = try containerValues.decodeIfPresent(Int.self, forKey: .statusCode)
        self = HttpResponse(body: .empty, statusCode: HttpStatusCode(rawValue: httpStatusCode ?? 404) ?? .notFound) as! Self
    }
}
