//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthState: CustomDebugStringConvertible {

    var debugDictionary: [String: Any] {
        let stateTypeDictionary: [String: Any] = ["AuthorizationState": type]
        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {
        case .notConfigured:
            additionalMetadataDictionary = [
                "AuthState": "notConfigured"
            ]
        case .configuringAuth:
            additionalMetadataDictionary = [
                "AuthState": "configuringAuth"
            ]
        case .configuringAuthentication(let authenticationState):
            additionalMetadataDictionary = [
                "AuthState": "configuringAuthentication",
                "- AuthenticationState": authenticationState.debugDictionary
            ]

        case .configuringAuthorization(let authenticationState, let authorizationState):
            additionalMetadataDictionary = [
                "AuthState": "configuringAuthorization",
                "- AuthenticationState": authenticationState.debugDictionary,
                "- AuthorizationState": authorizationState.debugDictionary
            ]
        case .configured(let authenticationState, let authorizationState):
            additionalMetadataDictionary = [
                "AuthState": "configured",
                "- AuthenticationState": authenticationState.debugDictionary,
                "- AuthorizationState": authorizationState.debugDictionary
            ]
        }
        return stateTypeDictionary.merging(additionalMetadataDictionary, uniquingKeysWith: { $1 })
    }

    var debugDescription: String {
        return (debugDictionary as AnyObject).description
    }
}
