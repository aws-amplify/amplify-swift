//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// HubChannel represents the channels on which Amplify category messages will be dispatched. Apps can define their own
/// channels for intra-app communication. Internally, Amplify uses the Hub for dispatching notifications about events
/// associated with different categories.
public enum HubChannel {
    /// Hub messages relating to Amplify Analytics
    case analytics

    /// Hub messages relating to Amplify API
    case api

    /// Hub messages relating to Amplify DataStore
    case dataStore

    /// Hub messages relating to Amplify Hub
    case hub

    /// Hub messages relating to Amplify Logging
    case logging

    /// Hub messages relating to Amplify Predictions
    case predictions

    /// Hub messages relating to Amplify Storage
    case storage

    /// A custom channel with its own name
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
    public static func == (lhs: HubChannel, rhs: HubChannel) -> Bool {
        switch (lhs, rhs) {
        case (.analytics, .analytics):
            return true
        case (.api, .api):
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
