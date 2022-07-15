//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

#if canImport(AuthenticationServices)

struct HostedUIOptions {

    let scopes: [String]

    let presentationAnchor: AuthUIPresentationAnchor?
}

extension HostedUIOptions: Codable {

    enum CodingKeys: String, CodingKey {
        case scopes
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        scopes = try values.decode(Array.self, forKey: .scopes)
        presentationAnchor = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scopes, forKey: .scopes)
    }
}

extension HostedUIOptions: Equatable { }

#endif
