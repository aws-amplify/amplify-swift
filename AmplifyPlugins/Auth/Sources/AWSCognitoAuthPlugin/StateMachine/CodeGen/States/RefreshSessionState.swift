//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum RefreshSessionState: State {

    case notStarted

    case refreshingUnAuthAWSCredentials(IdentityID)

    case refreshingUserPoolToken(AWSCognitoUserPoolTokens)

    case refreshingUserPoolTokenWithIdentity(AWSCognitoUserPoolTokens, IdentityID)

    case refreshingAWSCredentialsWithUserPoolTokens(AWSCognitoUserPoolTokens, IdentityID)

    case fetchingAuthSessionWithUserPool(FetchAuthSessionState, AWSCognitoUserPoolTokens)

    case refreshed(AmplifyCredentials)

}

extension RefreshSessionState: Equatable {

    static func == (lhs: RefreshSessionState, rhs: RefreshSessionState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
            (.refreshingUnAuthAWSCredentials, .refreshingUnAuthAWSCredentials),
            (.refreshingUserPoolToken, .refreshingUserPoolToken),
            (.refreshingUserPoolTokenWithIdentity, .refreshingUserPoolTokenWithIdentity),
            (.refreshingAWSCredentialsWithUserPoolTokens, .refreshingAWSCredentialsWithUserPoolTokens),
            (.fetchingAuthSessionWithUserPool, .fetchingAuthSessionWithUserPool),
            (.refreshed, .refreshed):
            return true

        default:
            return false
        }
    }

    var type: String {
        switch self {
        case .notStarted:
            return "RefreshSessionState.notStarted"
        case .refreshingUserPoolToken:
            return "RefreshSessionState.refreshingUserPoolToken"
        case .refreshingUserPoolTokenWithIdentity:
            return "RefreshSessionState.refreshingUserPoolTokenWithIdentity"
        case .refreshingAWSCredentialsWithUserPoolTokens:
            return "RefreshSessionState.refreshingAWSCredentialsWithUserPoolTokens"
        case .fetchingAuthSessionWithUserPool:
            return "RefreshSessionState.fetchingAuthSessionWithUserPool"
        case .refreshed:
            return "RefreshSessionState.refreshed"
        case .refreshingUnAuthAWSCredentials:
            return "RefreshSessionState.refreshingUnAuthAWSCredentials"
        }
    }
}
