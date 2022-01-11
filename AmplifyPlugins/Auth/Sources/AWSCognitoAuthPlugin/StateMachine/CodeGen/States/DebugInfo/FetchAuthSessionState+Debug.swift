//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FetchAuthSessionState {

    var debugDictionary: [String: Any] {
        let stateTypeDictionary: [String: Any] = ["FetchAuthSessionState": type]
        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {
        case .determiningUserState:
            additionalMetadataDictionary = [:]
        case .fetchingUserPoolTokens(let fetchUserPoolTokenState):
            additionalMetadataDictionary = [
                "- FetchUserPoolTokensState": fetchUserPoolTokenState.debugDictionary
            ]
        case .fetchingIdentity(let fetchIdentityState):
            additionalMetadataDictionary = [
                "- FetchIdentityState": fetchIdentityState.debugDictionary
            ]
        case .fetchingAWSCredentials(let fetchAWSCredentialState):
            additionalMetadataDictionary = [
                "- FetchAWSCredentialsState": fetchAWSCredentialState.debugDictionary
            ]
        case .sessionEstablished:
            additionalMetadataDictionary = [:]
        case .error:
            additionalMetadataDictionary = [:]
        }
        return stateTypeDictionary.merging(additionalMetadataDictionary, uniquingKeysWith: { $1 })
    }

}
