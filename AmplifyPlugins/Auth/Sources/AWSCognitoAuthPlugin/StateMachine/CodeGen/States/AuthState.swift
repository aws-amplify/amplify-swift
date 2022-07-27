//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum AuthState: State {

    case notConfigured

    case configuringAuth

    case validatingCredentialsAndConfiguration

    case configuringAuthentication(AuthenticationState)

    case configuringAuthorization(AuthenticationState, AuthorizationState)

    case configured(AuthenticationState, AuthorizationState)

}

extension AuthState {
    var type: String {
        switch self {
        case .notConfigured: return "AuthState.notConfigured"
        case .configuringAuth: return "AuthState.configuringAuth"
        case .validatingCredentialsAndConfiguration: return "AuthState.validatingCredentialsAndConfiguration"
        case .configuringAuthentication: return "AuthState.configuringAuthentication"
        case .configuringAuthorization: return "AuthState.configuringAuthorization"
        case .configured: return "AuthState.configured"
        }
    }
}
