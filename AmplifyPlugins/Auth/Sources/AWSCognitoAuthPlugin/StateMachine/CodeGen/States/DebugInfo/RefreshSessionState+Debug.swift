//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension RefreshSessionState {

    var debugDictionary: [String: Any] {
        var additionalMetadataDictionary: [String: Any] = [:]
        switch self {
        case .fetchingAuthSessionWithUserPool(let state, _):
            additionalMetadataDictionary = ["fetchingSession": state.debugDictionary]
        case .error(let error):
            additionalMetadataDictionary = ["error": error]
        default:
            additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }

}
