//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Common AppSync error types
public enum AppSyncErrorType: Equatable {

    private static let conditionalCheckFailedErrorString = "ConditionalCheckFailedException"
    private static let conflictUnhandledErrorString = "ConflictUnhandled"
    private static let unauthorizedErrorString = "Unauthorized"

    /// Conflict detection finds a version mismatch and the conflict handler rejects the mutation.
    /// See https://docs.aws.amazon.com/appsync/latest/devguide/conflict-detection-and-sync.html for more information
    case conflictUnhandled

    case conditionalCheck

    case unauthorized

    case unknown(String)

    public init(_ value: String) {
        switch value {
        case AppSyncErrorType.conditionalCheckFailedErrorString:
            self = .conditionalCheck
        case AppSyncErrorType.conflictUnhandledErrorString:
            self = .conflictUnhandled
        case AppSyncErrorType.unauthorizedErrorString:
            self = .unauthorized
        default:
            self = .unknown(value)
        }
    }

    public var rawValue: String {
        switch self {
        case .conditionalCheck:
            return AppSyncErrorType.conditionalCheckFailedErrorString
        case .conflictUnhandled:
            return AppSyncErrorType.conflictUnhandledErrorString
        case .unauthorized:
            return AppSyncErrorType.unauthorizedErrorString
        case .unknown(let value):
            return value
        }
    }
}
