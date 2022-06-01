//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthState: CustomDebugStringConvertible {

    var debugDictionary: [String: Any] {

        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {
        case .notConfigured:
            additionalMetadataDictionary = [:]
        case .configuringAuth:
            additionalMetadataDictionary = [:]
        case .configuringAuthentication(let authenticationState):
            additionalMetadataDictionary = authenticationState.debugDictionary

        case .configuringAuthorization(let authenticationState, let authorizationState):
            additionalMetadataDictionary = authenticationState.debugDictionary.merging(
                authorizationState.debugDictionary, uniquingKeysWith: {$1}
            )
        case .configured(let authenticationState, let authorizationState):
            additionalMetadataDictionary = authenticationState.debugDictionary.merging(
                authorizationState.debugDictionary, uniquingKeysWith: {$1}
            )
        }
        return [type: additionalMetadataDictionary]
    }

    var debugDescription: String {
        return (debugDictionary as AnyObject).description

    }
}
