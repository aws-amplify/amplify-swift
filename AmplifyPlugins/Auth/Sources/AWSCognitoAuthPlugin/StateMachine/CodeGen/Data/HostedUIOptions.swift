//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

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
        self.scopes = try values.decode(Array.self, forKey: .scopes)
        self.providerInfo = try values.decode(HostedUIProviderInfo.self, forKey: .providerInfo)
        self.preferPrivateSession = try values.decode(Bool.self, forKey: .preferPrivateSession)
        self.presentationAnchor = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(scopes, forKey: .scopes)
        try container.encode(providerInfo, forKey: .providerInfo)
        try container.encode(preferPrivateSession, forKey: .preferPrivateSession)
    }
}

extension HostedUIOptions: Equatable { }
