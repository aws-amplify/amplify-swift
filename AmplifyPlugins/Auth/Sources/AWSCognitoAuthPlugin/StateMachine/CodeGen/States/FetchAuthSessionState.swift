//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum FetchAuthSessionState: State {

    case initializingFetchAuthSession

    case fetchingUserPoolTokens(FetchUserPoolTokensState)

    case fetchingIdentity(FetchIdentityState)

    case fetchingAWSCredentials(FetchAWSCredentialsState)

    case sessionEstablished

}

public extension FetchAuthSessionState {
    var type: String {
        switch self {
        case .initializingFetchAuthSession: return "FetchAuthSessionState.initializingFetchAuthSession"
        case .fetchingUserPoolTokens: return "FetchAuthSessionState.fetchingUserPoolTokens"
        case .fetchingIdentity: return "FetchAuthSessionState.fetchingIdentity"
        case .fetchingAWSCredentials: return "FetchAuthSessionState.fetchingAwsCredentials"
        case .sessionEstablished: return "FetchAuthSessionState.sessionEstablished"
        }
    }
}
