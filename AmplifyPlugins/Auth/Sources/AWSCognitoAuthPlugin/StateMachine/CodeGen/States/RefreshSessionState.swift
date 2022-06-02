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

    case refreshingUserPoolToken(AWSCognitoUserPoolTokens, IdentityID?)

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
            return "FetchSessionState.notStarted"
        case .refreshingUserPoolToken:
            return "FetchSessionState.refreshingUserPoolToken"
        case .refreshingAWSCredentialsWithUserPoolTokens:
            return "FetchSessionState.refreshingAWSCredentialsWithUserPoolTokens"
        case .fetchingAuthSessionWithUserPool:
            return "FetchSessionState.fetchingAuthSessionWithUserPool"
        case .refreshed:
            return "FetchSessionState.refreshed"
        case .refreshingUnAuthAWSCredentials:
            return "FetchSessionState.refreshingUnAuthAWSCredentials"
        }
    }
}
