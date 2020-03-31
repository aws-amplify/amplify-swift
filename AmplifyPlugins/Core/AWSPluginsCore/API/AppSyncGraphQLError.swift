//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Error object returned from AppSync services
public class AppSyncGraphQLError<ResponseType: Decodable>: GraphQLError {
    public var message: String

    public var locations: [Location]?

    public var path: [JSONValue]?

    public var extensions: [String: JSONValue]?

    public var errorType: String?

    public var data: ResponseType?

    public init(message: String,
                locations: [Location]? = nil,
                path: [JSONValue]? = nil,
                extensions: [String: JSONValue]? = nil,
                errorType: String? = nil,
                data: ResponseType? = nil) {
        self.message = message
        self.locations = locations
        self.path = path
        self.extensions = extensions
        self.errorType = errorType
        self.data = data
    }
}

extension AppSyncGraphQLError {
    /// Convenient method for parsing `errorType` into one of AppSync's error types
    public var appSyncErrorType: AppSyncErrorType? {
        guard let errorType = self.errorType else { return nil }

        return AppSyncErrorType(value: errorType)
    }
}

/// Efficient way to check common AppSync error types
public enum AppSyncErrorType: Equatable {

    private static let conditionalCheckFailedErrorString = "ConditionalCheckFailedException"
    private static let conflictUnhandledErrorString = "ConflictUnhandled"

    /// Conflict detection finds a version mismatch and the conflict handler rejects the mutation.
    /// See https://docs.aws.amazon.com/appsync/latest/devguide/conflict-detection-and-sync.html for more information
    case conflictUnhandled

    case conditionalCheck

    case unknown(String)

    init(value: String) {
        switch value {
        case AppSyncErrorType.conditionalCheckFailedErrorString:
            self = .conditionalCheck
        case AppSyncErrorType.conflictUnhandledErrorString:
            self = .conflictUnhandled
        default:
            self = .unknown(value)
        }
    }

    var rawValue: String {
        switch self {
        case .conditionalCheck:
            return AppSyncErrorType.conditionalCheckFailedErrorString
        case .conflictUnhandled:
            return AppSyncErrorType.conflictUnhandledErrorString
        case .unknown(let value):
            return value
        }
    }
}
