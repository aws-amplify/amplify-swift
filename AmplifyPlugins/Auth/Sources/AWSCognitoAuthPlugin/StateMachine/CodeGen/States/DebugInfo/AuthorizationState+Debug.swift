//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthorizationState: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {
        case .notConfigured,
                .configured,
                .signingIn,
                .signingOut,
                .refreshingSession:
            additionalMetadataDictionary = [:]
        case .refreshingSession(existingCredentials: let credentials, let state):
            additionalMetadataDictionary = ["existing": credentials.debugDescription,
                                            "refreshState": state.debugDictionary]
        case .fetchingUnAuthSession(let state),
                .fetchingAuthSessionWithUserPool(let state, _):
            additionalMetadataDictionary = state.debugDictionary

        case .error(let error):
            additionalMetadataDictionary = ["Error": error]

        case .sessionEstablished(let credentials),
                .waitingToStore(let credentials):
            return [type: credentials.debugDescription]

        }
        return [type: additionalMetadataDictionary]
    }
}
