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

    case fetchingAuthSession(FetchAuthSessionState)

    case sessionEstablished(AWSAuthCognitoSession)

    case error(AuthorizationError)
}

extension AuthorizationState {
    var type: String {
        switch self {
        case .notConfigured: return "AuthorizationState.notConfigured"
        case .configured: return "AuthorizationState.configured"
        case .fetchingAuthSession: return "AuthorizationState.fetchingAuthSession"
        case .sessionEstablished: return "AuthorizationState.sessionEstablished"
        case .error: return "AuthorizationState.error"
        }
    }
}
