//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FetchAuthSessionState {

    var debugDictionary: [String: Any] {

        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {
        case .initializingFetchAuthSession:
            additionalMetadataDictionary = [:]
        case .fetchingUserPoolTokens(let state):
            additionalMetadataDictionary = state.debugDictionary
        case .fetchingIdentity(let state):
            additionalMetadataDictionary = state.debugDictionary
        case .fetchingAWSCredentials(let state):
            additionalMetadataDictionary = state.debugDictionary
        case .sessionEstablished:
            additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }

}
