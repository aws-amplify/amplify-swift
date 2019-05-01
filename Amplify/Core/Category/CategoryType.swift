//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Supertype to allow us use generic CategoryMarkers in Category and Plugin types.
public protocol CategoryMarkerProtocol {
    var categoryType: CategoryType { get }
}

/// We use CategoryMarker to associate Category and Plugin types at the Type level to allow for compile-time type
/// safety. Ideally, we'd simply associate them through the Category object itself, but this seems to set up some
/// circular relationships that Swift type inference can't quite parse.
public struct CategoryMarker {
    public struct Analytics: CategoryMarkerProtocol {
        public let categoryType = CategoryType.analytics
    }

    public struct API: CategoryMarkerProtocol {
        public let categoryType = CategoryType.api
    }

    public struct Auth: CategoryMarkerProtocol {
        public let categoryType = CategoryType.auth
    }

    public struct Hub: CategoryMarkerProtocol {
        public let categoryType = CategoryType.hub
    }

    public struct Logging: CategoryMarkerProtocol {
        public let categoryType = CategoryType.logging
    }

    public struct Storage: CategoryMarkerProtocol {
        public let categoryType = CategoryType.storage
    }
}

/// Amplify supports these Category types
public enum CategoryType: String {
    /// Record app metrics and analytics data
    case analytics

    /// Retrieve data from a remote service
    case api

    /// Identify and authorize users of your application
    case auth

    /// Listen for or dispatch Amplify events
    case hub

    /// Log Amplify and app messages
    case logging

    /// Upload and download files from the cloud
    case storage
}

extension CategoryType: CaseIterable {}
