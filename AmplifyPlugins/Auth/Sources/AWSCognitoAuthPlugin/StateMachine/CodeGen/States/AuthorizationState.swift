//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public enum AuthorizationState: State {

    case notConfigured

    case configured(AuthConfiguration)

    case fetchingAuthSession(FetchAuthSessionState)

    case sessionEstablished(AuthorizationSessionData)

    case validatingSession

    case error
}


public extension AuthorizationState {
    var type: String {
        switch self {
        case .notConfigured: return "AuthorizationState.notConfigured"
        case .configured: return "AuthorizationState.configured"
        case .fetchingAuthSession: return "AuthorizationState.fetchingAuthSession"
        case .sessionEstablished: return "AuthorizationState.sessionEstablished"
        case .validatingSession: return "AuthorizationState.validatingSession"
        case .error: return "AuthorizationState.error"
        }
    }
}
