//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package struct HostedUIProviderInfo: Equatable {

    package let authProvider: EngineAuthProvider?

    package let idpIdentifier: String?

    package init(
        authProvider: EngineAuthProvider?,
        idpIdentifier: String?
    ) {
        self.authProvider = authProvider
        self.idpIdentifier = idpIdentifier
    }
}

extension HostedUIProviderInfo: Codable {

    enum CodingKeys: String, CodingKey {

        case idpIdentifier
    }

    package init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.idpIdentifier = try values.decodeIfPresent(String.self, forKey: .idpIdentifier)
        self.authProvider = nil
    }

    package func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(idpIdentifier, forKey: .idpIdentifier)
    }
}
