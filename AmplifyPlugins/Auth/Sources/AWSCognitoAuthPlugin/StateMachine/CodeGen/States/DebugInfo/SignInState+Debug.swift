//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInState {

    var debugDictionary: [String: Any] {

        var additionalMetadataDictionary: [String: Any] = [:]

        switch self {

        case .signingInWithSRP(let srpSignInState, let signInEventData):
            additionalMetadataDictionary = srpSignInState.debugDictionary.merging(
                signInEventData.debugDictionary, uniquingKeysWith: {$1}
            )
        case .signingInWithHostedUI(let substate):
            additionalMetadataDictionary = substate.debugDictionary
        case .resolvingChallenge(let challengeState, let challengeType, let signInMethod):
            additionalMetadataDictionary = challengeState.debugDictionary
            additionalMetadataDictionary["challengeType"] = challengeType
            additionalMetadataDictionary["signInMethod"] = signInMethod

        case .notStarted:
            additionalMetadataDictionary = [:]
        case .signingInWithSRPCustom(let srpstate, _):
            additionalMetadataDictionary = ["SRPSignInStaet": srpstate.debugDictionary]
        case .signingInWithCustom(let customSignIn, _):
            additionalMetadataDictionary = ["CustomSignInState": customSignIn.debugDictionary]
        case .signingInViaMigrateAuth(let migrateSignInState, _):
            additionalMetadataDictionary = ["MigrateSignInState": migrateSignInState.debugDictionary]
        case .confirmingDevice:
            additionalMetadataDictionary = [:]
        case .resolvingDeviceSrpa(let deviceSRPState):
            additionalMetadataDictionary = ["DeviceSRPState": deviceSRPState.debugDictionary]
        case .signedIn(let data):
            additionalMetadataDictionary = ["SignedInData": data.debugDictionary]
        case .error:
            additionalMetadataDictionary = [:]
        }
        return [type: additionalMetadataDictionary]
    }
}
