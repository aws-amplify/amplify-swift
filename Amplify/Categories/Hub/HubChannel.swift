//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// HubChannel represents the channels on which Amplify category messages will be dispatched. Apps can define their own
/// channels for intra-app communication. Internally, Amplify uses the Hub for dispatching notifications about events
/// associated with different categories.
public enum HubChannel {

    /// <#Description#>
    case analytics

    /// <#Description#>
    case api

    /// <#Description#>
    case auth

    /// <#Description#>
    case dataStore

    /// <#Description#>
    case hub

    /// <#Description#>
    case logging

    /// <#Description#>
    case predictions

    /// <#Description#>
    case storage

    /// <#Description#>
    case custom(String)

    /// Convenience property to return an array of all non-`custom` channels
    static var amplifyChannels: [HubChannel] = {
        let categoryChannels = CategoryType
            .allCases
            .sorted { $0.displayName < $1.displayName }
            .map { HubChannel(from: $0) }
            .compactMap { $0 }

        return categoryChannels
    }()
}

extension HubChannel: Equatable {

    /// <#Description#>
    /// - Parameters:
    ///   - lhs: <#lhs description#>
    ///   - rhs: <#rhs description#>
    /// - Returns: <#description#>
    public static func == (lhs: HubChannel, rhs: HubChannel) -> Bool {
        switch (lhs, rhs) {
        case (.analytics, .analytics):
            return true
        case (.api, .api):
            return true
        case (.auth, .auth):
            return true
        case (.dataStore, .dataStore):
            return true
        case (.hub, .hub):
            return true
        case (.logging, .logging):
            return true
        case (.predictions, .predictions):
            return true
        case (.storage, .storage):
            return true
        case (.custom(let lhsValue), .custom(let rhsValue)):
            return lhsValue == rhsValue
        default:
            return false
        }
    }
}

extension HubChannel {
    public init(from categoryType: CategoryType) {
        switch categoryType {
        case .analytics:
            self = .analytics
        case .api:
            self = .api
        case .auth:
            self = .auth
        case .dataStore:
            self = .dataStore
        case .hub:
            self = .hub
        case .logging:
            self = .logging
        case .predictions:
            self = .predictions
        case .storage:
            self = .storage
        }
    }
}

extension HubChannel: Hashable { }
