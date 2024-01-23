//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify

public enum AppSyncRealTimeRequest {
    case connectionInit
    case start(StartRequest)
    case stop(String)

    public struct StartRequest {
        let id: String
        let data: String
        let auth: AppSyncRealTimeRequestAuth?
    }
}

extension AppSyncRealTimeRequest: Encodable {
    enum CodingKeys: CodingKey {
        case type
        case payload
        case id
    }

    enum PayloadCodingKeys: CodingKey {
        case data
        case extensions
    }

    enum ExtensionsCodingKeys: CodingKey {
        case authorization
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .connectionInit:
            try container.encode("connection_init", forKey: .type)
        case .start(let startRequest):
            try container.encode("start", forKey: .type)
            try container.encode(startRequest.id, forKey: .id)

            let payloadEncoder = container.superEncoder(forKey: .payload)
            var payloadContainer = payloadEncoder.container(keyedBy: PayloadCodingKeys.self)
            try payloadContainer.encode(startRequest.data, forKey: .data)

            let extensionEncoder = payloadContainer.superEncoder(forKey: .extensions)
            var extensionContainer = extensionEncoder.container(keyedBy: ExtensionsCodingKeys.self)
            try extensionContainer.encodeIfPresent(startRequest.auth, forKey: .authorization)
        case .stop(let id):
            try container.encode("stop", forKey: .type)
            try container.encode(id, forKey: .id)
        }
    }
}
