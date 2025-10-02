//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct HostedUIProviderInfo: Equatable {

    let authProvider: AuthProvider?

    let idpIdentifier: String?
}

extension HostedUIProviderInfo: Codable {

    enum CodingKeys: String, CodingKey {

        case idpIdentifier
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.idpIdentifier = try values.decodeIfPresent(String.self, forKey: .idpIdentifier)
        self.authProvider = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(idpIdentifier, forKey: .idpIdentifier)
    }
}
