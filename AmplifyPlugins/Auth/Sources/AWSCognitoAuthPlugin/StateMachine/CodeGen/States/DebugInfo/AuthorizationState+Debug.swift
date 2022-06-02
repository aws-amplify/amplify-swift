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
        case .notConfigured:
            additionalMetadataDictionary = [:]
        case .configured:
            additionalMetadataDictionary = [:]
        case .fetchingAuthSession(let state):
            additionalMetadataDictionary = state.debugDictionary
        case .signingIn:
            additionalMetadataDictionary = [:]
        case .sessionEstablished(let credentials):
            return [type: credentials.debugDescription]
        case .error(let error):
            additionalMetadataDictionary = ["Error": error]
        }
        return [type: additionalMetadataDictionary]
    }
}
