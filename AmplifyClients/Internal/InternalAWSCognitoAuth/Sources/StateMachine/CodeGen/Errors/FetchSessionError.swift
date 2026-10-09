//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AWSCognitoIdentity
import ClientRuntime
import Foundation

package enum FetchSessionError: Error {

    case noIdentityPool

    case noUserPool

    case invalidTokens

    case notAuthorized

    case invalidIdentityID

    case invalidAWSCredentials

    case noCredentialsToRefresh

    case federationNotSupportedDuringRefresh

    case service(Error)
}

extension FetchSessionError: Equatable {
    package static func == (lhs: FetchSessionError, rhs: FetchSessionError) -> Bool {
        switch (lhs, rhs) {
        case (.noIdentityPool, .noIdentityPool),
            (.noUserPool, .noUserPool),
            (.notAuthorized, .notAuthorized),
            (.invalidTokens, .invalidTokens),
            (.invalidIdentityID, .invalidIdentityID),
            (.noCredentialsToRefresh, .noCredentialsToRefresh),
            (.invalidAWSCredentials, .invalidAWSCredentials),
            (.federationNotSupportedDuringRefresh, .federationNotSupportedDuringRefresh),
            (.service, .service):
            return true
        default: return false
        }
    }
}

extension FetchSessionError: EngineAuthErrorConvertible {
    package var engineError: EngineAuthError {
        switch self {
        case .noIdentityPool:
            return .configuration(
                "No identity pool configuration found",
                AuthPluginErrorConstants.configurationError
            )
        case .noUserPool:
            return .configuration(
                "No user pool configuration found",
                AuthPluginErrorConstants.configurationError
            )
        case .invalidTokens:
            return .unknown(
                "Invalid tokens received when refreshing session")
        case .notAuthorized:
            return .notAuthorized(
                "Not authorized error",
                AuthPluginErrorConstants.notAuthorizedError
            )
        case .invalidIdentityID:
            return .unknown("Invalid identity id received when fetching session")
        case .invalidAWSCredentials:
            return .unknown("Invalid temporary AWS Credentials received when fetching session")
        case .noCredentialsToRefresh:
            return .service(
                "No credentials found to refresh",
                EngineErrorMessages.reportBugToAWS(function: Self.reportBugFunction)
            )
        case .federationNotSupportedDuringRefresh:
            return .unknown(
                "Refreshing credentials from federationToIdentityPool is not supported \(EngineErrorMessages.reportBugToAWS(function: Self.reportBugFunction))")
        case .service(let error):
            if let convertibleError = error as? EngineAuthErrorConvertible {
                return convertibleError.engineError
            } else {
                return .service(
                    "Service error occurred",
                    EngineErrorMessages.reportBugToAWS(function: Self.reportBugFunction),
                    error
                )
            }
        }
    }

    /// The `function:` that `reportBugToAWS()` has always embedded here: the text was originally built in
    /// `var authError`. Kept so the recovery text is unchanged.
    private static let reportBugFunction: StaticString = "authError"

}
