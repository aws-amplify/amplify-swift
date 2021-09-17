//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The Amplify category with which the conforming type is associated. Categories, Plugins, ClientBehaviors, etc must
/// all share the same CategoryType
public protocol CategoryTypeable {
    var categoryType: CategoryType { get }
}

/// Amplify supports these Category types
public enum CategoryType: String {
    /// Record app metrics and analytics data
    case analytics

    /// Retrieve data from a remote service
    case api

    /// Authentication
    case auth

    /// Persist data
    case dataStore

    /// Interact with geospatial services
    case geo

    /// Listen for or dispatch Amplify events
    case hub

    /// Log Amplify and app messages
    case logging

    /// Prediction
    case predictions

    /// Upload and download files from the cloud
    case storage
}

extension CategoryType: CaseIterable {}

public extension CategoryType {
    var displayName: String {
        switch self {
        case .analytics:
            return "Analytics"
        case .api:
            return "API"
        case .auth:
            return "Authentication"
        case .dataStore:
            return "DataStore"
        case .geo:
            return "Geo"
        case .hub:
            return "Hub"
        case .logging:
            return "Logging"
        case .predictions:
            return "Predictions"
        case .storage:
            return "Storage"
        }
    }

    var category: Category {
        switch self {
        case .analytics:
            return Amplify.Analytics
        case .api:
            return Amplify.API
        case .auth:
            return Amplify.Auth
        case .dataStore:
            return Amplify.DataStore
        case .geo:
            return Amplify.Geo
        case .hub:
            return Amplify.Hub
        case .logging:
            return Amplify.Logging
        case .predictions:
            return Amplify.Predictions
        case .storage:
            return Amplify.Storage
        }
    }
}
