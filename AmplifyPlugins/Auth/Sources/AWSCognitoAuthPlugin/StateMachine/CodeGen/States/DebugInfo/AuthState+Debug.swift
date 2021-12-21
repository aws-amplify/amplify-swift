//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthState: CustomDebugStringConvertible {

    public var debugDictionary: [String: Any] {
        switch self {
        case .notConfigured:
            return
             [
                 "AuthState": "notConfigured"
             ]

        case .configuring:
            return
             [
                 "AuthState": "configuring"
             ]

        case .configuringAuthentication(let authenticationState):
           return
            [
                "AuthState": "configuringAuthentication",
                "- AuthenticationState": authenticationState.debugDictionary
            ]

        case .configuringAuthorization(let authenticationState, let authorizationState):
            return [
                "AuthState": "configuringAuthorization",
                "- AuthenticationState": authenticationState.debugDictionary,
                "- AuthorizationState": authorizationState.debugDictionary
            ]

        case .configured(let authenticationState, let authorizationState):
            return [
                "AuthState": "configured",
                "- AuthenticationState": authenticationState.debugDictionary,
                "- AuthorizationState": authorizationState.debugDictionary
            ]
        }
    }

    public var debugDescription: String {
        return (debugDictionary as AnyObject).description
    }
}
