//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public enum AuthState: State {

    case notConfigured

    case configuringCredentialStore(CredentialStoreState)

    case configuringAuthentication(AuthenticationState)

    case configuringAuthorization(AuthenticationState, AuthorizationState)

    case configured(AuthenticationState, AuthorizationState)

}

public extension AuthState {
    var type: String {
        switch self {
        case .notConfigured: return "AuthState.notConfigured"
        case .configuringCredentialStore: return "AuthState.configuringCredentialStore"
        case .configuringAuthentication: return "AuthState.configuringAuthentication"
        case .configuringAuthorization: return "AuthState.configuringAuthorization"
        case .configured: return "AuthState.configured"
        }
    }
}
