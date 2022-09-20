//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import ClientRuntime

extension ChangePasswordOutputResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case httpResponse = "httpResponse"
    }

    public init(from decoder: Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        guard let httpResponse = try containerValues.decodeIfPresent(HttpResponse.self, forKey: .httpResponse) else {
            fatalError("Unable to decode http response")
        }
        try self.init(httpResponse: httpResponse)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeNil(forKey: .httpResponse)
    }

}
