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

    case refreshingUserPoolToken(SignedInData)

    case refreshingUserPoolTokenWithIdentity(SignedInData, IdentityID)

    case refreshingAWSCredentialsWithUserPoolTokens(SignedInData, IdentityID)

    case fetchingAuthSessionWithUserPool(FetchAuthSessionState, SignedInData)

    case refreshed(AmplifyCredentials)

    case error(FetchSessionError)

}

extension RefreshSessionState: Equatable {

    static func == (lhs: RefreshSessionState, rhs: RefreshSessionState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
            (.refreshingUnAuthAWSCredentials, .refreshingUnAuthAWSCredentials),
            (.refreshingUserPoolToken, .refreshingUserPoolToken),
            (.refreshingUserPoolTokenWithIdentity, .refreshingUserPoolTokenWithIdentity),
            (.refreshingAWSCredentialsWithUserPoolTokens, .refreshingAWSCredentialsWithUserPoolTokens),
            (.refreshed, .refreshed),
            (.error, .error):
            return true
        case  (.fetchingAuthSessionWithUserPool(let lhsFetchState, _),
            .fetchingAuthSessionWithUserPool(let rhsFetchState, _)):
            return lhsFetchState == rhsFetchState
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
        case .error:
            return "RefreshSessionState.error"
        }
    }
}
