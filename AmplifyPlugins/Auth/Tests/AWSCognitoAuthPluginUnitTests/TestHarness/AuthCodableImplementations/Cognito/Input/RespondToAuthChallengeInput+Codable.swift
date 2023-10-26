//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//




extension RespondToAuthChallengeInput: Decodable {
    enum CodingKeys: String, CodingKey {

        case clientId

    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let clientId = try values.decode(String.self, forKey: .clientId)

        self.init(clientId: clientId)

    }
}
