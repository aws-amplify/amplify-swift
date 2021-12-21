//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


public extension SRPSignInState {

    var debugDictionary: [String: Any] {
        let stateTypeDictionary: [String: Any] = ["SRPSignInState": type]
        var additionalMetadataDictionary: [String: Any] = [:]
        switch self {
        case .notStarted:
            additionalMetadataDictionary = [:]
        case .initiatingSRPA(let signInEventData):
            additionalMetadataDictionary = [
                "- SignInEventData": signInEventData.debugDictionary
            ]
        case .cancelling:
            additionalMetadataDictionary = [:]
        case .nextAuthChallenge(let awsAuthChallenge):
            additionalMetadataDictionary = [
                "- AWSAuthChallengeData": awsAuthChallenge
            ]
        case .respondingPasswordVerifier(let srpStateData):
            additionalMetadataDictionary = [
                "- SRPStateData": srpStateData.debugDictionary
            ]
        case .signedIn(let signedInData):
            additionalMetadataDictionary = [
                "- SignedInData": signedInData.debugDictionary
            ]
        case .error(let error):
            additionalMetadataDictionary = [
                "- AuthenticationError": error
            ]
        }
        return stateTypeDictionary.merging(additionalMetadataDictionary, uniquingKeysWith: { $1 })
    }
}
