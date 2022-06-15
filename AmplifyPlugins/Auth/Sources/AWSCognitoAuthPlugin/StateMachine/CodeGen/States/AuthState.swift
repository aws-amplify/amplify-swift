//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


enum AuthState: State {

    case notConfigured

    case configuringCredentialStore(CredentialStoreState)

    case configuringAuthentication(AuthenticationState)

    case configuringAuthorization(AuthenticationState, AuthorizationState)

    case configured(AuthenticationState, AuthorizationState)

}

extension AuthState {
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
