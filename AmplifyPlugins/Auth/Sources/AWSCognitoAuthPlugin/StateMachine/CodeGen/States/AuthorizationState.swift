//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum AuthorizationState: State {

    case notConfigured

    case configured

    case signingIn

    case fetchingUnAuthSession(FetchAuthSessionState)

    case fetchingAuthSessionWithUserPool(FetchAuthSessionState,
                                         AWSCognitoUserPoolTokens)

    case waitingToStore(AmplifyCredentials)

    case sessionEstablished(AmplifyCredentials)

    case error(AuthorizationError)
}

extension AuthorizationState {
    var type: String {
        switch self {
        case .notConfigured:
            return "AuthorizationState.notConfigured"
        case .configured:
            return "AuthorizationState.configured"
        case .signingIn:
            return "AuthorizationState.signingIn"
        case .fetchingUnAuthSession:
            return "AuthorizationState.fetchingUnAuthSession"
        case .sessionEstablished:
            return "AuthorizationState.sessionEstablished"
        case .waitingToStore:
            return "AuthorizationState.waitingToStore"
        case .fetchingAuthSessionWithUserPool:
            return "AuthorizationState.fetchingAuthSessionWithUserPool"
        case .error:
            return "AuthorizationState.error"
        }
    }
}
