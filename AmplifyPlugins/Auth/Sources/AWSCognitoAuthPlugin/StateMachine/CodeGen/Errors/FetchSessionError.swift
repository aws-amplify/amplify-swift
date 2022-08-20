//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentity
import ClientRuntime
import Foundation

enum FetchSessionError: Error {

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
    static func == (lhs: FetchSessionError, rhs: FetchSessionError) -> Bool {
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

extension FetchSessionError: AuthErrorConvertible {
    var authError: AuthError {
        switch self {
        case .noIdentityPool:
            return .configuration(
                "No identity pool configuration found",
                AuthPluginErrorConstants.configurationError)
        case .noUserPool:
            return .configuration(
                "No user pool configuration found",
                AuthPluginErrorConstants.configurationError)
        case .invalidTokens:
            return .unknown(
                "Invalid tokens received when refreshing session")
        case .notAuthorized:
            return .notAuthorized(
                "Not authorized error",
                AuthPluginErrorConstants.notAuthorizedError)
        case .invalidIdentityID:
            return .unknown("Invalid identity id received when fetching session")
        case .invalidAWSCredentials:
            return .unknown("Invalid temporary AWS Credentials received when fetching session")
        case .noCredentialsToRefresh:
            return .service(
                "No credentials found to refresh",
                AmplifyErrorMessages.reportBugToAWS())
        case .federationNotSupportedDuringRefresh:
            return .unknown(
                "Federation triggered during refresh session that is not supported. \(AmplifyErrorMessages.reportBugToAWS())")
        case .service(let error):
            return .service(
                "Service error occurred",
                AmplifyErrorMessages.reportBugToAWS(),
                error)
        }
    }


}

