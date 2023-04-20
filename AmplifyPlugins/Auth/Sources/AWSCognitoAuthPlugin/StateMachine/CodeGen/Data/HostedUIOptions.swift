//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

#if !os(watchOS)

struct HostedUIOptions {

    let scopes: [String]

    let providerInfo: HostedUIProviderInfo

    let presentationAnchor: AuthUIPresentationAnchor?

    let preferPrivateSession: Bool
}

extension HostedUIOptions: Codable {

    enum CodingKeys: String, CodingKey {

        case scopes

        case providerInfo

        case preferPrivateSession
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        scopes = try values.decode(Array.self, forKey: .scopes)
        providerInfo = try values.decode(HostedUIProviderInfo.self, forKey: .providerInfo)
        preferPrivateSession = try values.decode(Bool.self, forKey: .preferPrivateSession)
        presentationAnchor = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scopes, forKey: .scopes)
        try container.encode(providerInfo, forKey: .providerInfo)
        try container.encode(preferPrivateSession, forKey: .preferPrivateSession)
    }
}

extension HostedUIOptions: Equatable { }

#endif
