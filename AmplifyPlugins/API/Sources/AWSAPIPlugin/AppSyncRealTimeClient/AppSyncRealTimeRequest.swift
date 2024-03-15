//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Combine
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

    var id: String? {
        switch self {
        case let .start(request): return request.id
        case let .stop(id): return id
        default: return nil
        }
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


extension AppSyncRealTimeRequest {
    public enum Error: Swift.Error, Equatable {
        case timeout
        case limitExceeded
        case maxSubscriptionsReached
        case unauthorized
        case unknown(message: String? = nil, causedBy: Swift.Error? = nil, payload: [String: Any]?)

        var isUnknown: Bool {
            if case .unknown = self {
                return true
            }
            return false
        }

        public static func == (lhs: AppSyncRealTimeRequest.Error, rhs: AppSyncRealTimeRequest.Error) -> Bool {
            switch (lhs, rhs) {
            case (.timeout, .timeout),
                 (.limitExceeded, .limitExceeded),
                 (.maxSubscriptionsReached, .maxSubscriptionsReached),
                 (.unauthorized, .unauthorized):
                return true
            default:
                return false
            }
        }
    }


    public static func parseResponseError(
        error: JSONValue
    ) -> AppSyncRealTimeRequest.Error? {
        let limitExceededErrorString = "LimitExceededError"
        let maxSubscriptionsReachedErrorString = "MaxSubscriptionsReachedError"
        let unauthorized = "Unauthorized"

        guard let errorType = error.errorType?.stringValue else {
            return nil
        }

        switch errorType {
        case _ where errorType.contains(limitExceededErrorString):
            return .limitExceeded
        case _ where errorType.contains(maxSubscriptionsReachedErrorString):
            return .maxSubscriptionsReached
        case _ where errorType.contains(unauthorized):
            return .unauthorized
        default:
            return .unknown(
                message: error.message?.stringValue,
                causedBy: nil,
                payload: error.asObject
            )
        }
    }
}
